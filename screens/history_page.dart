import 'package:flutter/material.dart';
import 'Article_page.dart';
import '../services/search_log_service.dart';

class HistoryPage extends StatefulWidget {
  static const String route = '/history';
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _logs = [];
  bool _loading = true;

  // ✅ 用英文命名並定義目前登入使用者的 ID
  // 這裡先假設你已經在登入時取得 userId，可替換成實際取得的值
  late int currentUserId;

  @override
  void initState() {
    super.initState();
    // ⚡️範例：這裡先寫死為 1，實務上應該從登入流程或 SharedPreferences 取得
    currentUserId = 1;
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final data = await SearchLogService.fetchUserLogs(currentUserId);
      setState(() {
        _logs = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _logs = [];
        _loading = false;
      });
      // 可以視情況加入錯誤提示
      debugPrint('讀取瀏覽紀錄失敗: $e');
    }
  }

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
        title: const Text(
          "瀏覽歷史",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text("目前沒有瀏覽紀錄"))
          : ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return ListTile(
            title: Text(log['query'] ?? ''),
            subtitle: Text('搜尋時間：${log['searched_at']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleDetailPage(
                    articleId: int.tryParse(log['search_result'] ?? '0') ?? 0,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}