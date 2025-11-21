import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';

class AIacc extends StatefulWidget {
  static const String route = '/aiacc';

  const AIacc({super.key});

  @override
  State<AIacc> createState() => _AIaccState();
}

class _AIaccState extends State<AIacc> {
  final TextEditingController _textController = TextEditingController();

  String? _selectedFileName;
  List<Map<String, dynamic>> _historyQueries = [];
  bool _isLoadingHistory = false;
  bool _expandedHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistoryQueries();
  }

  // ============================================================
  // 讀取最近 5 筆聊天紀錄（後端 /api/chat/recent）
  // ============================================================
  Future<void> _loadHistoryQueries() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.userId ?? 0;

    if (userId == 0) {
      setState(() => _historyQueries = []);
      return;
    }

    setState(() {
      _isLoadingHistory = true;
      _historyQueries = [];
    });

    final apiBase = kIsWeb
        ? "http://127.0.0.1:5000/api"
        : "http://10.0.2.2:5000/api";

    final url = "$apiBase/chat/recent?user_id=$userId&limit=5";

    try {
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode == 200) {
        final jsonMap = jsonDecode(resp.body);
        final List records = jsonMap["records"] ?? [];

        setState(() {
          _historyQueries = records.map((r) {
            return {
              "id": r["id"],
              "title": r["query_text"] ?? "",
              "created_at": r["created_at"],
              "gemini_result": r["gemini_result"] ?? {},
              "conversation": r["conversation"] ?? [],
            };
          }).toList();
        });
      } else {
        print("❌ 讀取歷史紀錄錯誤: ${resp.body}");
      }
    } catch (e) {
      print("❌ 錯誤: $e");
    }

    setState(() => _isLoadingHistory = false);
  }

  // ============================================================
  // 選擇檔案
  // ============================================================
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() => _selectedFileName = result.files.single.name);
      } else {
        setState(() => _selectedFileName = null);
      }
    } catch (e) {
      print("檔案選擇錯誤: $e");
    }
  }

  // ============================================================
  // 新的查證 → 前往 AIchat（會 call /chat/start）
  // ============================================================
  void _navigateToChat() {
    final query = _textController.text.trim();

    String message;
    if (_selectedFileName != null && query.isNotEmpty) {
      message = '查證訊息： "$query" 並分析檔案 "$_selectedFileName"';
    } else if (_selectedFileName != null) {
      message = '查證檔案： "$_selectedFileName"';
    } else if (query.isNotEmpty) {
      message = '查證訊息： "$query"';
    } else {
      message = '請查證...';
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AIchat(initialQuery: message)),
    ).then((_) => _loadHistoryQueries());

    _textController.clear();
    setState(() => _selectedFileName = null);
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _topBanner(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleSection(),
                  const SizedBox(height: 20),
                  _inputBox(),
                  const SizedBox(height: 20),
                  _uploadBox(),
                  const SizedBox(height: 30),
                  _verifyButton(),
                  const SizedBox(height: 30),
                  _historySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI Widgets
  // ============================================================
  Widget _topBanner() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '真假小助手',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Image.asset('lib/assets/logo2.png', width: 80, height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "幫您查證資訊真假",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text("輸入可疑訊息、網址或上傳圖片/影片", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _inputBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _textController,
        maxLines: 5,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "  請輸入可疑訊息…",
        ),
      ),
    );
  }

  Widget _uploadBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text("上傳圖片/影片"),
          const SizedBox(height: 10),
          if (_selectedFileName != null)
            Text(
              "已選擇：$_selectedFileName",
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ElevatedButton(onPressed: _pickFile, child: const Text("選擇文件")),
        ],
      ),
    );
  }

  Widget _verifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text("立即查證", style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _historySection() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyQueries.isEmpty) {
      return const Center(child: Text("尚無查證紀錄"));
    }

    final list = _expandedHistory ? _historyQueries : _historyQueries.take(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "歷史查詢",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (_, index) {
            final q = list.elementAt(index);

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AIchat(
                      sessionId: q["id"], // ⭐ 回到舊 session
                      initialQuery: "", // 不需要
                      existingConversation: q["conversation"],
                      createdAt: q["created_at"],
                      title: q["title"],
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q["title"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q["created_at"],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_historyQueries.length > 3)
          TextButton(
            onPressed: () => setState(() {
              _expandedHistory = !_expandedHistory;
            }),
            child: Text(_expandedHistory ? "顯示較少" : "顯示全部"),
          ),
      ],
    );
  }
}
