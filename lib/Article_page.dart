import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "文章詳情",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "新冠疫苗含有微型晶片追蹤人體活動?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "疫情謠言",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("發布時間：2025-05-20 08:30",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            // AI可信度卡片
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI可信度分析",
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          "可信度評分：15分",
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "（滿分100分）",
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.15,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "依據多項權威資料判斷，該說法屬於錯誤訊息，可信度極低。所謂“疫苗含有微型晶片”，缺乏任何科學依據，專家一致認為這是典型的謠言訊息。",
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              "【本報訊】",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "近期，網傳謠言稱新冠疫苗含有微型晶片可以追蹤人體活動，甚至聲稱疫苗接種卡是一種國際監控工具。根據ISO編碼標準，疫苗接種人員證件僅是為了確認接種紀錄，不具備追蹤功能。專家表示，這種說法純屬捏造，缺乏科學依據。",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              "相關調查顯示，疫苗晶片說法最早出現在部分海外社群媒體，經過轉發和加工，迅速傳入國內，引發恐慌。專家指出，所謂“微型晶片”不存在，疫苗成分經過嚴格檢驗，接種安全性獲得充分保證。",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              "目前國內《疫苗管理法》《傳染病防治法》等均對疫苗管理有明確規範。醫學界強調，接種新冠疫苗的主要目的是預防感染和重症，並無追蹤人體活動的功能。對於這類謠言，專家提醒公眾應保持警惕，不輕信、不傳播。",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "相關權威闢謠",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _buildFactItem("WHO：COVID-19疫苗不含追蹤晶片。"),
                  _buildFactItem("中國疾控中心：新冠疫苗安全有效。"),
                  _buildFactItem("美國FDA：新冠疫苗成分均公開透明。"),
                  _buildFactItem("上千條實驗數據證明疫苗不存在微型晶片。"),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.thumb_up_alt_outlined, color: Colors.grey),
                  Icon(Icons.star_border, color: Colors.grey),
                  Icon(Icons.share_outlined, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }
}


