import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pkg from 'pg';
import bcrypt from 'bcryptjs';
import fetch from 'node-fetch';

dotenv.config();
const { Pool } = pkg;

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: Number(process.env.PG_PORT || 5432),
  database: process.env.PG_DATABASE || 'truthliesdetector',
  user: process.env.PG_USER || 'postgres',
  password: process.env.PG_PASSWORD || '1234'
});

// Python 服務位址（可用環境變數覆蓋）
const PY_SERVICE_BASE_URL = process.env.PY_SERVICE_BASE_URL || 'http://localhost:5001';

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// 註冊
app.post('/api/register', async (req, res) => {
  const { account, username, password, email, phone } = req.body || {};
  if (!account || !username || !password || !email) {
    return res.status(400).json({ error: '缺少必要欄位' });
  }
  try {
    // 檢查帳號/Email 重複
    const acc = await pool.query('SELECT 1 FROM public.users WHERE account=$1', [account]);
    if (acc.rowCount > 0) return res.status(409).json({ error: '帳號已存在' });

    const em = await pool.query('SELECT 1 FROM public.users WHERE email=$1', [email]);
    if (em.rowCount > 0) return res.status(409).json({ error: '電子郵件已被使用' });

    // 加密
    const hashed = bcrypt.hashSync(password, 10);

    await pool.query(
      'INSERT INTO public.users (account, username, password, email, phone) VALUES ($1,$2,$3,$4,$5)',
      [account, username, hashed, email, phone || null]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '註冊失敗' });
  }
});

// 登入
app.post('/api/login', async (req, res) => {
  const { account, password } = req.body || {};
  if (!account || !password) return res.status(400).json({ error: '缺少必要欄位' });
  try {
    const result = await pool.query(
      'SELECT user_id, account, username, password, email, phone FROM public.users WHERE account=$1',
      [account]
    );
    if (result.rowCount === 0) return res.status(401).json({ error: '帳號或密碼錯誤' });

    const user = result.rows[0];
    const ok = bcrypt.compareSync(password, user.password);
    if (!ok) return res.status(401).json({ error: '帳號或密碼錯誤' });

    // 回傳不含密碼
    delete user.password;
    res.json({ ok: true, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '登入失敗' });
  }
});

// 查詢用戶
app.get('/api/users/:id', async (req, res) => {
  const id = Number(req.params.id);
  try {
    const result = await pool.query(
      'SELECT user_id, account, username, email, phone FROM public.users WHERE user_id=$1',
      [id]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: '找不到用戶' });
    res.json({ ok: true, user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '查詢失敗' });
  }
});

// 更新用戶
app.put('/api/users/:id', async (req, res) => {
  const id = Number(req.params.id);
  const { username, email, phone } = req.body || {};
  try {
    await pool.query(
      'UPDATE public.users SET username=$1, email=$2, phone=$3 WHERE user_id=$4',
      [username, email, phone || null, id]
    );
    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '更新失敗' });
  }
});

// 新聞分析 API
app.post('/api/analyze-news', async (req, res) => {
  const { url } = req.body || {};
  if (!url) {
    return res.status(400).json({ error: '缺少網址參數' });
  }
  
  try {
    // 執行 Python 分析腳本
    const { spawn } = require('child_process');
    const scriptPath = '../analyze_news.py';
    
    const python = spawn('python', [scriptPath, url], {
      cwd: __dirname
    });
    
    let output = '';
    let errorOutput = '';
    
    python.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    python.stderr.on('data', (data) => {
      errorOutput += data.toString();
    });
    
    python.on('close', (code) => {
      if (code !== 0) {
        console.error('Python script error:', errorOutput);
        return res.status(500).json({ error: '分析過程發生錯誤', details: errorOutput });
      }
      
      try {
        // 解析 Python 腳本的 JSON 輸出
        const result = JSON.parse(output);
        res.json({ ok: true, analysis: result });
      } catch (parseError) {
        console.error('JSON parse error:', parseError);
        console.log('Raw output:', output);
        res.status(500).json({ error: 'JSON 解析失敗', raw_output: output });
      }
    });
    
    // 設定超時
    setTimeout(() => {
      python.kill();
      res.status(408).json({ error: '分析超時' });
    }, 30000); // 30 秒超時
    
  } catch (err) {
    console.error('Analysis error:', err);
    res.status(500).json({ error: '分析失敗', details: err.message });
  }
});

// 代理：圖片分析（轉發到 Flask OpenCV 服務）
app.post('/api/image-check', async (req, res) => {
  try {
    const url = `${PY_SERVICE_BASE_URL}/analyze-image`;
    const resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body || {})
    });
    const data = await resp.json();
    res.status(resp.status).json(data);
  } catch (err) {
    console.error('Proxy image-check error:', err);
    res.status(500).json({ ok: false, error: '影像分析服務不可用' });
  }
});

// 取得假訊息統計資料 API
app.get('/api/fake-news-stats', async (req, res) => {
  try {
    // 這裡可以從資料庫或檔案系統讀取之前的分析結果
    // 使用更新的模擬資料，讓變化更明顯
    const stats = {
      weeklyReports: [
        { day: '一', verified: 12, suspicious: 18 },
        { day: '二', verified: 15, suspicious: 22 },
        { day: '三', verified: 8, suspicious: 28 },
        { day: '四', verified: 18, suspicious: 32 },
        { day: '五', verified: 20, suspicious: 25 },
        { day: '六', verified: 14, suspicious: 19 },
        { day: '日', verified: 16, suspicious: 21 }
      ],
      totalVerified: 45,  // 更新數字
      totalSuspicious: 189, // 更新數字
      aiAccuracy: 92, // 更新準確率
      topCategories: [
        { name: '🔥 AI 深偽技術相關假訊息', percentage: 42 }, // 新的分類
        { name: '🏥 醫療保健謠言', percentage: 31 },
        { name: '💰 投資詐騙相關', percentage: 19 },
        { name: '🗳️ 政治選舉傳言', percentage: 8 }
      ],
      // 新增：傳播途徑分佈（供圓餅圖使用）
      propagationChannels: [
        { channel: '社群媒體', percentage: 55 },
        { channel: '私人訊息群組', percentage: 30 },
        { channel: '傳統媒體/網站', percentage: 15 }
      ]
    };
    res.json({ ok: true, stats });
  } catch (err) {
    console.error('Stats error:', err);
    res.status(500).json({ error: '取得統計資料失敗' });
  }
});

const PORT = Number(process.env.PORT || 8080);
app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
