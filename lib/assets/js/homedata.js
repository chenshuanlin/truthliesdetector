// server.js
import express from "express";
import pkg from "pg";
import cors from "cors";

const { Pool } = pkg;
const app = express();
app.use(cors());

const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "truthliesdetector",
  password: "1234",
  port: 5432,
});

// 取得熱門文章
app.get("/articles/trending", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT article_id, title, category, reliability_score, published_time
      FROM articles
      ORDER BY reliability_score DESC NULLS LAST, published_time DESC
      LIMIT 5
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

// 取得推薦主題
app.get("/articles/recommend", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT category, COUNT(*) AS count
      FROM articles
      GROUP BY category
      ORDER BY count DESC
      LIMIT 5
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
});

app.listen(3000, () => console.log("API server running on port 3000"));
