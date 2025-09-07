import 'package:flutter/material.dart';

class AppColors {
  static const Color lightGreenBG = Color(0xFFE3EFE4);
  static const Color deepGreen = Color(0xFF4D704A);
  static const Color labelGreenBG = Color(0xFFD7EAD9);
  static const Color userGray = Color(0xFFCCCCCC);
  static const Color darkText = Color(0xFF333333);
  static const Color alertred = Color(0xFFD85E5E);
}

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF8DA391),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "文章詳情",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD85E5E),
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _buildReportDialog(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFD85E5E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "低可信度",
                          style: TextStyle(color: Colors.white, fontSize: 12),
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
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.15,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
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

                  // 相似新聞比對
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreenBG,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "相似新聞比對",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFactItem("WHO：COVID-19疫苗不含追蹤晶片，此為謠言"),
                        _buildFactItem("台灣疾管署：疫苗成分公開透明，無追蹤裝置"),
                        _buildFactItem("科學家解釋：疫苗微晶片說法在技術上不可能實現"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 用戶互動區
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.article_outlined, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.darkText),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.labelGreenBG,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "官方發布",
              style: TextStyle(fontSize: 11, color: AppColors.deepGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.lightGreenBG,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "用戶互動區",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.deepGreen,
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildCommentItem("李醫師（流行病學專家）",
                  "疫苗不可能植入晶片，針頭直徑僅0.25~0.5mm，現有晶片技術無法藏於疫苗中且人體無感覺。",
                  isExpert: true),
              const Divider(),
              _buildCommentItem("張小明", "感謝澄清，我差點被親戚帶偏，現在可以安心接種疫苗了。"),
              const Divider(),
              _buildCommentInputBox(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(String name, String content, {bool isExpert = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isExpert ? AppColors.deepGreen : AppColors.userGray,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExpert ? AppColors.deepGreen : Colors.black87)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(fontSize: 13, color: AppColors.darkText)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCommentInputBox() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "留下您的評論...",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.userGray, width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
                child: const Text("發送", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.arrow_upward, color: AppColors.deepGreen, size: 20),
              SizedBox(width: 8),
              Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReportDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGreenBG,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "疑慮內容回報",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "為了協助我們更準確地處理您提交的回報，請簡要說明您對這篇文章的疑慮。以下是一些常見的舉報理由供您參考：\n"
                  "· 涉及不實資訊或誤導內容\n"
                  "· 含有仇恨言論、歧視或人身攻擊\n"
                  "· 涉及暴力、色情或其他不當內容\n"
                  "· 侵犯他人隱私或智慧財產權\n"
                  "· 與平台規範不符的廣告或垃圾訊息\n\n"
                  "請盡可能具體說明問題所在，感謝您的協助！",
              style: TextStyle(fontSize: 13, color: AppColors.darkText, height: 1.5),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "請說明舉報理由...",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertred,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: 舉報提交處理
                },
                child: const Text(
                  "舉報",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
