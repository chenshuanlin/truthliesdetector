from faker import Faker
import psycopg2
from random import choice, randint
from datetime import datetime, timedelta

fake = Faker("zh_TW")

# -------------------
# PostgreSQL 連線
# -------------------
conn = psycopg2.connect(
    host="localhost",
    port=5433,
    dbname="truthliesdetector",
    user="postgres",
    password="1234"
)
cur = conn.cursor()



# -------------------
# 清空資料表並重置序列
# -------------------
'''
tables = [
    "analysis_results",
    "articles",
    "comments",
    "favorites",
    "related_news",
    "reports",
    "search_logs",
    "users"
]
cur.execute(f"TRUNCATE TABLE {', '.join(tables)} RESTART IDENTITY CASCADE;")
print("🗑️ 已清空所有資料表，並重置自增序列。")

# -------------------
# 1️⃣ Users
# -------------------
user_ids = []
for _ in range(5):
    account = fake.user_name()
    username = fake.name()
    email = fake.email()
    password = 'password123'
    phone = fake.phone_number()
    cur.execute(
        "INSERT INTO users (account, username, password, email, phone) VALUES (%s,%s,%s,%s,%s) RETURNING user_id",
        (account, username, password, email, phone)
    )
    user_ids.append(cur.fetchone()[0])

# -------------------
# 2️⃣ Articles (使用你提供的 5 篇新聞)
# -------------------
articles_data = [
    {
        "title": "台灣科技新創獲投資",
        "content": "今天台灣科技公司A獲得B億元投資，專注AI領域創新應用，未來將開發智慧醫療解決方案。",
        "category": "科技",
        "source_link": "https://example.com/news1",
        "media_name": "科技日報",
        "created_time": datetime.now() - timedelta(days=2),
        "published_time": datetime.now() - timedelta(days=1),
        "reliability_score": 0.95
    },
    {
        "title": "台北市舉辦國際藝術展",
        "content": "台北市文化局今日宣布國際藝術展將於下週開幕，展出來自世界各地藝術家的作品。",
        "category": "藝術",
        "source_link": "https://example.com/news2",
        "media_name": "藝術觀察",
        "created_time": datetime.now() - timedelta(days=5),
        "published_time": datetime.now() - timedelta(days=3),
        "reliability_score": 0.92
    },
    {
        "title": "中華隊勇奪國際棒球賽冠軍",
        "content": "中華隊在國際棒球賽中以7比3擊敗對手，成功奪冠，球迷熱情慶祝全場氣氛沸騰。",
        "category": "體育",
        "source_link": "https://example.com/news3",
        "media_name": "體育新聞",
        "created_time": datetime.now() - timedelta(days=3),
        "published_time": datetime.now() - timedelta(days=2),
        "reliability_score": 0.97
    },
    {
        "title": "新北市推出智慧交通系統",
        "content": "新北市政府推出智慧交通系統，透過AI分析路況，提升通勤效率，減少交通事故發生率。",
        "category": "科技",
        "source_link": "https://example.com/news4",
        "media_name": "都市科技",
        "created_time": datetime.now() - timedelta(days=4),
        "published_time": datetime.now() - timedelta(days=2),
        "reliability_score": 0.93
    },
    {
        "title": "環保署呼籲減塑運動",
        "content": "環保署宣布啟動全國減塑運動，鼓勵民眾減少一次性塑膠用品使用，共同守護環境。",
        "category": "環境",
        "source_link": "https://example.com/news5",
        "media_name": "環保時報",
        "created_time": datetime.now() - timedelta(days=1),
        "published_time": datetime.now(),
        "reliability_score": 0.94
    }
]

article_ids = []
for art in articles_data:
    cur.execute(
        """INSERT INTO articles 
           (title, content, category, source_link, media_name, created_time, published_time, reliability_score)
           VALUES (%s,%s,%s,%s,%s,%s,%s,%s) RETURNING article_id""",
        (art["title"], art["content"], art["category"], art["source_link"], art["media_name"],
         art["created_time"], art["published_time"], art["reliability_score"])
    )
    article_ids.append(cur.fetchone()[0])

# -------------------
# 3️⃣ Comments
# -------------------
for article_id in article_ids:
    for _ in range(3):  # 每篇文章 3 筆留言
        user_id = choice(user_ids)
        content = f"{fake.sentence(nb_words=6)}（針對文章：{articles_data[article_ids.index(article_id)]['title']}）"
        commented_at = datetime.now() - timedelta(days=randint(0,5))
        user_identity = choice(['驗證使用者','訪客'])
        cur.execute(
            "INSERT INTO comments (user_id, article_id, content, commented_at, user_identity) VALUES (%s,%s,%s,%s,%s)",
            (user_id, article_id, content, commented_at, user_identity)
        )

# -------------------
# 4️⃣ Favorites
# -------------------
favorite_pairs = set()
for _ in range(5):
    while True:
        user_id = choice(user_ids)
        article_id = choice(article_ids)
        pair = (user_id, article_id)
        if pair not in favorite_pairs:
            favorite_pairs.add(pair)
            break
    favorited_at = datetime.now() - timedelta(days=randint(0,5))
    cur.execute(
        "INSERT INTO favorites (user_id, article_id, favorited_at) VALUES (%s,%s,%s)",
        (user_id, article_id, favorited_at)
    )

# -------------------
# 5️⃣ Analysis Results
# -------------------
risk_levels = ['低','中','高']
for article_id in article_ids:
    user_id = choice(user_ids)
    explanation = f"分析文章「{articles_data[article_ids.index(article_id)]['title']}」的內容趨勢與關鍵字"
    analyzed_at = datetime.now() - timedelta(days=randint(0,5))
    keywords = ', '.join(fake.words(nb=3))
    category = articles_data[article_ids.index(article_id)]["category"]
    confidence_score = round(randint(80,99)/100,2)
    risk_level = choice(risk_levels)
    report_id = None
    cur.execute(
        """INSERT INTO analysis_results
           (article_id, user_id, explanation, analyzed_at, keywords, category, confidence_score, risk_level, report_id)
           VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
        (article_id, user_id, explanation, analyzed_at, keywords, category, confidence_score, risk_level, report_id)
    )

# -------------------
# 6️⃣ Related News
# -------------------
related_pairs = set()
for article_id in article_ids:
    others = [a for a in article_ids if a != article_id]
    related_article_id = choice(others)
    pair = (article_id, related_article_id)
    if pair not in related_pairs:
        related_pairs.add(pair)
        similarity_score = round(randint(60,95)/100,2)
        related_title = f"相關文章：{articles_data[article_ids.index(related_article_id)]['title']}"
        related_link = articles_data[article_ids.index(related_article_id)]["source_link"]
        cur.execute(
            "INSERT INTO related_news (source_article_id, related_article_id, similarity_score, related_title, related_link) VALUES (%s,%s,%s,%s,%s)",
            (article_id, related_article_id, similarity_score, related_title, related_link)
        )

# -------------------
# 7️⃣ Reports
# -------------------
statuses = ['開啟','已關閉']
for _ in range(5):
    user_id = choice(user_ids)
    article_id = choice(article_ids)
    reason = f"檢舉文章「{articles_data[article_ids.index(article_id)]['title']}」內容不當"
    status = choice(statuses)
    reported_at = datetime.now() - timedelta(days=randint(0,5))
    cur.execute(
        "INSERT INTO reports (user_id, article_id, reason, status, reported_at) VALUES (%s,%s,%s,%s,%s)",
        (user_id, article_id, reason, status, reported_at)
    )

# -------------------
# 8️⃣ Search Logs
# -------------------
for user_id in user_ids:
    query = choice(["科技","環境","藝術","體育"])
    search_result = ", ".join([f"{articles_data[i]['title']}" for i in range(len(articles_data)) if articles_data[i]["category"]==query])
    searched_at = datetime.now() - timedelta(days=randint(0,5))
    cur.execute(
        "INSERT INTO search_logs (user_id, query, search_result, searched_at) VALUES (%s,%s,%s,%s)",
        (user_id, query, search_result, searched_at)
    )
'''

# -------------------
# 提交並關閉
# -------------------
conn.commit()
cur.close()
conn.close()


