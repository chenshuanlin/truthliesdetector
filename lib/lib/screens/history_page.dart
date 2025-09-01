import 'package:flutter/material.dart';
import 'Article_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 模擬瀏覽紀錄資料
  final List<Map<String, String>> history = const [
    {
      "title": "台灣氣象局：花蓮外海規模5.8地震，各地區震度統計出爐",
      "date": "2025-05-20 08:30",
      "content": "地震造成部分建築輕微損壞，無人員傷亡"
    },
    {
      "title": "新冠肺炎疫苗接種率提升，公共衛生監測報告",
      "date": "2025-05-19 14:10",
      "content": "全台疫苗接種率達到85%，疫情控制良好"
    },
    {
      "title": "科技公司發布最新AI語音助理，支援多國語言",
      "date": "2025-05-18 09:00",
      "content": "新產品具備即時翻譯與情緒辨識功能"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF9EB79E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Align(
          alignment: Alignment.centerLeft, // 靠左
          child: Text(
            "瀏覽歷史",
            style: TextStyle(
              color: Colors.white, // 白色文字
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: false, // 取消置中
      ),
      body: history.isEmpty
          ? const Center(child: Text("目前沒有瀏覽紀錄"))
          : ListView.builder(
        itemCount: history.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final article = history[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側綠線
                Container(
                  width: 4,
                  height: 80,
                  color: const Color(0xFF9EB79E),
                ),
                // 文章內容
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 文章標題
                        Text(
                          article["title"] ?? "",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // 發布時間 + 查看詳情
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "發布時間：${article["date"] ?? ""}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1A3D7A), // 深藍色
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                // ✅ 跳轉到 ArticlePage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ArticleDetailPage(
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "查看詳情 >>",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
