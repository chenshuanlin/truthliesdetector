import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pkg from 'pg';
import bcrypt from 'bcryptjs';

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

const PORT = Number(process.env.PORT || 8080);
app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
