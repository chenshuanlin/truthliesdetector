--
-- PostgreSQL database dump
--

\restrict 8kMwRN6WSGttpCCDG5meXJzD1EtiByoOqgE9i5E8CMMCcHWFN0gl5kilqC3zCzu

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

-- Started on 2025-09-17 19:18:06

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 16560)
-- Name: analysis_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analysis_results (
    analysis_id integer NOT NULL,
    article_id integer,
    user_id integer,
    explanation text,
    analyzed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    keywords text,
    category character varying(50),
    confidence_score numeric(3,2),
    risk_level character varying(20),
    report_id integer
);


ALTER TABLE public.analysis_results OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16566)
-- Name: analysis_results_analysis_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analysis_results_analysis_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analysis_results_analysis_id_seq OWNER TO postgres;

--
-- TOC entry 4988 (class 0 OID 0)
-- Dependencies: 218
-- Name: analysis_results_analysis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analysis_results_analysis_id_seq OWNED BY public.analysis_results.analysis_id;


--
-- TOC entry 219 (class 1259 OID 16567)
-- Name: articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articles (
    article_id integer NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    category character varying(50),
    source_link text,
    media_name character varying(100),
    created_time timestamp without time zone,
    published_time timestamp without time zone,
    reliability_score numeric(3,2)
);


ALTER TABLE public.articles OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16572)
-- Name: articles_article_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.articles_article_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.articles_article_id_seq OWNER TO postgres;

--
-- TOC entry 4989 (class 0 OID 0)
-- Dependencies: 220
-- Name: articles_article_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.articles_article_id_seq OWNED BY public.articles.article_id;


--
-- TOC entry 221 (class 1259 OID 16573)
-- Name: comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments (
    comment_id integer NOT NULL,
    user_id integer,
    article_id integer,
    content text,
    commented_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_identity character varying(50)
);


ALTER TABLE public.comments OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16579)
-- Name: comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comments_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comments_comment_id_seq OWNER TO postgres;

--
-- TOC entry 4990 (class 0 OID 0)
-- Dependencies: 222
-- Name: comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comments_comment_id_seq OWNED BY public.comments.comment_id;


--
-- TOC entry 223 (class 1259 OID 16580)
-- Name: favorites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorites (
    favorite_id integer NOT NULL,
    user_id integer,
    article_id integer,
    favorited_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.favorites OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16584)
-- Name: favorites_favorite_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.favorites_favorite_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.favorites_favorite_id_seq OWNER TO postgres;

--
-- TOC entry 4991 (class 0 OID 0)
-- Dependencies: 224
-- Name: favorites_favorite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.favorites_favorite_id_seq OWNED BY public.favorites.favorite_id;


--
-- TOC entry 225 (class 1259 OID 16585)
-- Name: related_news; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.related_news (
    related_id integer NOT NULL,
    source_article_id integer,
    related_article_id integer,
    similarity_score numeric(3,2),
    related_title character varying(200),
    related_link text
);


ALTER TABLE public.related_news OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16590)
-- Name: related_news_related_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.related_news_related_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.related_news_related_id_seq OWNER TO postgres;

--
-- TOC entry 4992 (class 0 OID 0)
-- Dependencies: 226
-- Name: related_news_related_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.related_news_related_id_seq OWNED BY public.related_news.related_id;


--
-- TOC entry 227 (class 1259 OID 16591)
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    report_id integer NOT NULL,
    user_id integer,
    article_id integer,
    reason text,
    status character varying(20),
    reported_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16597)
-- Name: reports_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reports_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reports_report_id_seq OWNER TO postgres;

--
-- TOC entry 4993 (class 0 OID 0)
-- Dependencies: 228
-- Name: reports_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reports_report_id_seq OWNED BY public.reports.report_id;


--
-- TOC entry 229 (class 1259 OID 16598)
-- Name: search_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.search_logs (
    search_id integer NOT NULL,
    user_id integer,
    query text,
    search_result text,
    searched_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.search_logs OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16604)
-- Name: search_logs_search_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.search_logs_search_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.search_logs_search_id_seq OWNER TO postgres;

--
-- TOC entry 4994 (class 0 OID 0)
-- Dependencies: 230
-- Name: search_logs_search_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.search_logs_search_id_seq OWNED BY public.search_logs.search_id;


--
-- TOC entry 231 (class 1259 OID 16605)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    account character varying(50) NOT NULL,
    username character varying(50) NOT NULL,
    password character varying(100) NOT NULL,
    email character varying(100),
    phone text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16608)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 4995 (class 0 OID 0)
-- Dependencies: 232
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 4777 (class 2604 OID 16609)
-- Name: analysis_results analysis_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results ALTER COLUMN analysis_id SET DEFAULT nextval('public.analysis_results_analysis_id_seq'::regclass);


--
-- TOC entry 4779 (class 2604 OID 16610)
-- Name: articles article_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles ALTER COLUMN article_id SET DEFAULT nextval('public.articles_article_id_seq'::regclass);


--
-- TOC entry 4780 (class 2604 OID 16611)
-- Name: comments comment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments ALTER COLUMN comment_id SET DEFAULT nextval('public.comments_comment_id_seq'::regclass);


--
-- TOC entry 4782 (class 2604 OID 16612)
-- Name: favorites favorite_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites ALTER COLUMN favorite_id SET DEFAULT nextval('public.favorites_favorite_id_seq'::regclass);


--
-- TOC entry 4784 (class 2604 OID 16613)
-- Name: related_news related_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_news ALTER COLUMN related_id SET DEFAULT nextval('public.related_news_related_id_seq'::regclass);


--
-- TOC entry 4785 (class 2604 OID 16614)
-- Name: reports report_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports ALTER COLUMN report_id SET DEFAULT nextval('public.reports_report_id_seq'::regclass);


--
-- TOC entry 4787 (class 2604 OID 16615)
-- Name: search_logs search_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.search_logs ALTER COLUMN search_id SET DEFAULT nextval('public.search_logs_search_id_seq'::regclass);


--
-- TOC entry 4789 (class 2604 OID 16616)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 4967 (class 0 OID 16560)
-- Dependencies: 217
-- Data for Name: analysis_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.analysis_results (analysis_id, article_id, user_id, explanation, analyzed_at, keywords, category, confidence_score, risk_level, report_id) FROM stdin;
1	1	3	分析文章「台灣科技新創獲投資」的內容趨勢與關鍵字	2025-09-17 15:14:14.190296	全部, 問題, 一種	科技	0.98	高	1
2	2	5	分析文章「台北市舉辦國際藝術展」的內容趨勢與關鍵字	2025-09-12 15:14:14.192297	之間, 查看, 關於	藝術	0.83	低	5
3	3	4	分析文章「中華隊勇奪國際棒球賽冠軍」的內容趨勢與關鍵字	2025-09-17 15:14:14.193296	任何, 能力, 無法	體育	0.90	高	3
4	4	3	分析文章「新北市推出智慧交通系統」的內容趨勢與關鍵字	2025-09-17 15:14:14.193296	專業, 電子, 當前	科技	0.97	中	2
5	5	4	分析文章「環保署呼籲減塑運動」的內容趨勢與關鍵字	2025-09-17 15:14:14.193296	大家, 一切, 投資	環境	0.95	中	4
\.


--
-- TOC entry 4969 (class 0 OID 16567)
-- Dependencies: 219
-- Data for Name: articles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.articles (article_id, title, content, category, source_link, media_name, created_time, published_time, reliability_score) FROM stdin;
1	台灣科技新創獲投資	今天台灣科技公司A獲得B億元投資，專注AI領域創新應用，未來將開發智慧醫療解決方案。	科技	https://example.com/news1	科技日報	2025-09-15 15:14:14.168621	2025-09-16 15:14:14.168621	0.95
2	台北市舉辦國際藝術展	台北市文化局今日宣布國際藝術展將於下週開幕，展出來自世界各地藝術家的作品。	藝術	https://example.com/news2	藝術觀察	2025-09-12 15:14:14.168621	2025-09-14 15:14:14.168621	0.92
3	中華隊勇奪國際棒球賽冠軍	中華隊在國際棒球賽中以7比3擊敗對手，成功奪冠，球迷熱情慶祝全場氣氛沸騰。	體育	https://example.com/news3	體育新聞	2025-09-14 15:14:14.168621	2025-09-15 15:14:14.169635	0.97
4	新北市推出智慧交通系統	新北市政府推出智慧交通系統，透過AI分析路況，提升通勤效率，減少交通事故發生率。	科技	https://example.com/news4	都市科技	2025-09-13 15:14:14.169635	2025-09-15 15:14:14.169635	0.93
5	環保署呼籲減塑運動	環保署宣布啟動全國減塑運動，鼓勵民眾減少一次性塑膠用品使用，共同守護環境。	環境	https://example.com/news5	環保時報	2025-09-16 15:14:14.169635	2025-09-17 15:14:14.169635	0.94
\.


--
-- TOC entry 4971 (class 0 OID 16573)
-- Dependencies: 221
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (comment_id, user_id, article_id, content, commented_at, user_identity) FROM stdin;
1	5	1	對於過程時間信息不斷.（針對文章：台灣科技新創獲投資）	2025-09-13 15:14:14.177077	訪客
2	1	1	今年你的價格如此語言這個你的.（針對文章：台灣科技新創獲投資）	2025-09-15 15:14:14.182732	訪客
3	5	1	經驗部門記者建設那麼關系能力.（針對文章：台灣科技新創獲投資）	2025-09-14 15:14:14.182732	驗證使用者
4	4	2	能夠工程搜索東西.（針對文章：台北市舉辦國際藝術展）	2025-09-15 15:14:14.182732	驗證使用者
5	2	2	可以她的感覺完全同時用戶文章.（針對文章：台北市舉辦國際藝術展）	2025-09-14 15:14:14.182732	驗證使用者
6	3	2	幫助系列起來怎麼通過次數免費.（針對文章：台北市舉辦國際藝術展）	2025-09-15 15:14:14.182732	訪客
7	1	3	增加的人學生威望文化更多學生結果.（針對文章：中華隊勇奪國際棒球賽冠軍）	2025-09-16 15:14:14.183741	訪客
8	4	3	工具原因有關大家一些.（針對文章：中華隊勇奪國際棒球賽冠軍）	2025-09-13 15:14:14.183741	驗證使用者
9	1	3	閱讀表示主題查看以及設計.（針對文章：中華隊勇奪國際棒球賽冠軍）	2025-09-17 15:14:14.184745	訪客
10	2	4	國家發表希望經濟出來作品.（針對文章：新北市推出智慧交通系統）	2025-09-12 15:14:14.185731	驗證使用者
11	3	4	你的瀏覽銷售下載如果開始.（針對文章：新北市推出智慧交通系統）	2025-09-13 15:14:14.185731	訪客
12	4	4	會員作品一種專業以及.（針對文章：新北市推出智慧交通系統）	2025-09-16 15:14:14.185731	驗證使用者
13	4	5	應用以及擁有各種經驗科技來源.（針對文章：環保署呼籲減塑運動）	2025-09-12 15:14:14.185731	訪客
14	3	5	處理問題謝謝介紹.（針對文章：環保署呼籲減塑運動）	2025-09-17 15:14:14.185731	訪客
15	1	5	其他最大今天.（針對文章：環保署呼籲減塑運動）	2025-09-16 15:14:14.185731	驗證使用者
\.


--
-- TOC entry 4973 (class 0 OID 16580)
-- Dependencies: 223
-- Data for Name: favorites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.favorites (favorite_id, user_id, article_id, favorited_at) FROM stdin;
1	1	5	2025-09-14 15:14:14.185731
2	3	3	2025-09-16 15:14:14.18928
3	5	3	2025-09-13 15:14:14.18928
4	1	3	2025-09-16 15:14:14.18928
5	4	2	2025-09-12 15:14:14.18928
\.


--
-- TOC entry 4975 (class 0 OID 16585)
-- Dependencies: 225
-- Data for Name: related_news; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.related_news (related_id, source_article_id, related_article_id, similarity_score, related_title, related_link) FROM stdin;
1	1	2	0.64	相關文章：台北市舉辦國際藝術展	https://example.com/news2
2	2	4	0.67	相關文章：新北市推出智慧交通系統	https://example.com/news4
3	3	5	0.60	相關文章：環保署呼籲減塑運動	https://example.com/news5
4	4	5	0.72	相關文章：環保署呼籲減塑運動	https://example.com/news5
5	5	1	0.82	相關文章：台灣科技新創獲投資	https://example.com/news1
\.


--
-- TOC entry 4977 (class 0 OID 16591)
-- Dependencies: 227
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (report_id, user_id, article_id, reason, status, reported_at) FROM stdin;
1	4	5	檢舉文章「環保署呼籲減塑運動」內容不當	開啟	2025-09-14 15:14:14.198833
2	5	5	檢舉文章「環保署呼籲減塑運動」內容不當	已關閉	2025-09-15 15:14:14.200854
3	4	3	檢舉文章「中華隊勇奪國際棒球賽冠軍」內容不當	開啟	2025-09-12 15:14:14.200854
4	3	1	檢舉文章「台灣科技新創獲投資」內容不當	已關閉	2025-09-16 15:14:14.200854
5	5	4	檢舉文章「新北市推出智慧交通系統」內容不當	開啟	2025-09-16 15:14:14.200854
\.


--
-- TOC entry 4979 (class 0 OID 16598)
-- Dependencies: 229
-- Data for Name: search_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.search_logs (search_id, user_id, query, search_result, searched_at) FROM stdin;
1	1	藝術	台北市舉辦國際藝術展	2025-09-12 15:14:14.200854
2	2	藝術	台北市舉辦國際藝術展	2025-09-15 15:14:14.203857
3	3	科技	台灣科技新創獲投資, 新北市推出智慧交通系統	2025-09-15 15:14:14.203857
4	4	體育	中華隊勇奪國際棒球賽冠軍	2025-09-17 15:14:14.205182
5	5	體育	中華隊勇奪國際棒球賽冠軍	2025-09-17 15:14:14.205712
\.


--
-- TOC entry 4981 (class 0 OID 16605)
-- Dependencies: 231
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, account, username, password, email, phone) FROM stdin;
1	ya-lingyeh	游家豪	password123	jkao@example.net	0912961931
2	chun-hsien14	蔡芸菲	password123	hsiu-chinyeh@example.net	06 1363174
3	xpan	柳明德	password123	hsiu-chin22@example.net	08 8110359
4	pliao	黃冠霖	password123	wen-hua66@example.org	0921330441
5	shsu	張佳蓉	password123	gchen@example.net	074 76679216
6	123	123	123456	123@gmail.com	0912345678
\.


--
-- TOC entry 4996 (class 0 OID 0)
-- Dependencies: 218
-- Name: analysis_results_analysis_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.analysis_results_analysis_id_seq', 5, true);


--
-- TOC entry 4997 (class 0 OID 0)
-- Dependencies: 220
-- Name: articles_article_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.articles_article_id_seq', 5, true);


--
-- TOC entry 4998 (class 0 OID 0)
-- Dependencies: 222
-- Name: comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comment_id_seq', 15, true);


--
-- TOC entry 4999 (class 0 OID 0)
-- Dependencies: 224
-- Name: favorites_favorite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.favorites_favorite_id_seq', 5, true);


--
-- TOC entry 5000 (class 0 OID 0)
-- Dependencies: 226
-- Name: related_news_related_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.related_news_related_id_seq', 5, true);


--
-- TOC entry 5001 (class 0 OID 0)
-- Dependencies: 228
-- Name: reports_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_report_id_seq', 5, true);


--
-- TOC entry 5002 (class 0 OID 0)
-- Dependencies: 230
-- Name: search_logs_search_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.search_logs_search_id_seq', 5, true);


--
-- TOC entry 5003 (class 0 OID 0)
-- Dependencies: 232
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 6, true);


--
-- TOC entry 4791 (class 2606 OID 16618)
-- Name: analysis_results analysis_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_pkey PRIMARY KEY (analysis_id);


--
-- TOC entry 4793 (class 2606 OID 16620)
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (article_id);


--
-- TOC entry 4795 (class 2606 OID 16622)
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (comment_id);


--
-- TOC entry 4797 (class 2606 OID 16624)
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (favorite_id);


--
-- TOC entry 4799 (class 2606 OID 16626)
-- Name: favorites favorites_user_id_article_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_article_id_key UNIQUE (user_id, article_id);


--
-- TOC entry 4801 (class 2606 OID 16628)
-- Name: related_news related_news_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_news
    ADD CONSTRAINT related_news_pkey PRIMARY KEY (related_id);


--
-- TOC entry 4803 (class 2606 OID 16630)
-- Name: related_news related_news_source_article_id_related_article_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_news
    ADD CONSTRAINT related_news_source_article_id_related_article_id_key UNIQUE (source_article_id, related_article_id);


--
-- TOC entry 4805 (class 2606 OID 16632)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (report_id);


--
-- TOC entry 4807 (class 2606 OID 16634)
-- Name: search_logs search_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.search_logs
    ADD CONSTRAINT search_logs_pkey PRIMARY KEY (search_id);


--
-- TOC entry 4809 (class 2606 OID 16636)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4810 (class 2606 OID 16637)
-- Name: analysis_results analysis_results_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(article_id);


--
-- TOC entry 4811 (class 2606 OID 16642)
-- Name: analysis_results analysis_results_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(report_id);


--
-- TOC entry 4812 (class 2606 OID 16647)
-- Name: analysis_results analysis_results_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4813 (class 2606 OID 16652)
-- Name: comments comments_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(article_id);


--
-- TOC entry 4814 (class 2606 OID 16657)
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4815 (class 2606 OID 16662)
-- Name: favorites favorites_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(article_id);


--
-- TOC entry 4816 (class 2606 OID 16667)
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4817 (class 2606 OID 16672)
-- Name: related_news related_news_related_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_news
    ADD CONSTRAINT related_news_related_article_id_fkey FOREIGN KEY (related_article_id) REFERENCES public.articles(article_id);


--
-- TOC entry 4818 (class 2606 OID 16677)
-- Name: related_news related_news_source_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.related_news
    ADD CONSTRAINT related_news_source_article_id_fkey FOREIGN KEY (source_article_id) REFERENCES public.articles(article_id);


--
-- TOC entry 4819 (class 2606 OID 16682)
-- Name: reports reports_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.articles(article_id);


--
-- TOC entry 4820 (class 2606 OID 16687)
-- Name: reports reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4821 (class 2606 OID 16692)
-- Name: search_logs search_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.search_logs
    ADD CONSTRAINT search_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


-- Completed on 2025-09-17 19:18:06

--
-- PostgreSQL database dump complete
--

\unrestrict 8kMwRN6WSGttpCCDG5meXJzD1EtiByoOqgE9i5E8CMMCcHWFN0gl5kilqC3zCzu

