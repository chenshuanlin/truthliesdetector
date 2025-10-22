import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';

class AIaccScreen extends StatefulWidget {
  static const String route = '/aiacc';
  final int? userId; // 🧩 綁定使用者 ID

  const AIaccScreen({super.key, this.userId});

  @override
  State<AIaccScreen> createState() => _AIaccScreenState();
}

class _AIaccScreenState extends State<AIaccScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController(); // 🔍 搜尋框控制器
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isAnalyzing = false;
  bool _showAllHistory = false;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = []; // 🔍 篩選後紀錄
  Map<String, dynamic>? _latestResult;

  final String apiBase =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5000');

  @override
  void initState() {
    super.initState();
    _loadHistoryFromDatabase();
    _searchController.addListener(_onSearchChanged);
  }

  // ================================================================
  // 📜 從後端撈取聊天紀錄
  // ================================================================
  Future<void> _loadHistoryFromDatabase() async {
    try {
      final uid = widget.userId ?? 0;
      final response = await http.get(Uri.parse('$apiBase/chat/history?user_id=$uid&limit=50'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        setState(() {
          _history = records;
          _filteredHistory = records;
        });
      }
    } catch (e) {
      debugPrint("⚠️ 無法讀取聊天紀錄：$e");
    }
  }

  // ================================================================
  // 🔍 搜尋篩選
  // ================================================================
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _filteredHistory = _history);
    } else {
      setState(() {
        _filteredHistory = _history
            .where((item) =>
                (item['query_text'] ?? '').toString().contains(query) ||
                (item['ai_acc_result'] ?? {})
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // ================================================================
  // 📁 選取檔案
  // ================================================================
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
      );
      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      debugPrint("❌ 檔案選擇錯誤: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("選取檔案時發生錯誤：$e")));
    }
  }

  // ================================================================
  // 🧠 呼叫 Flask /analyze（新對話）
  // ================================================================
  Future<void> _sendToBackend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入文字或上傳圖片／影片！")),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      http.Response response;
      if (_selectedFileBytes == null) {
        response = await http.post(
          Uri.parse('$apiBase/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        );
      } else {
        final request = http.MultipartRequest('POST', Uri.parse('$apiBase/analyze'));
        request.fields['input'] = text;
        final fileNameLower = _selectedFileName!.toLowerCase();
        final mediaType = fileNameLower.endsWith('.jpg') ||
                fileNameLower.endsWith('.jpeg') ||
                fileNameLower.endsWith('.png')
            ? MediaType('image', 'jpeg')
            : MediaType('video', 'mp4');

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFileBytes!,
          filename: _selectedFileName!,
          contentType: mediaType,
        ));
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final queryText = text.isEmpty ? _selectedFileName ?? '' : text;
        setState(() {
          _latestResult = result;
          _history.insert(0, {
            'query_text': queryText,
            'ai_acc_result': result,
            'created_at': DateTime.now().toIso8601String(),
          });
          _filteredHistory = _history;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIchat(
              initialQuery: queryText,
              backendResult: result,
              capturedImageBytes: _selectedFileBytes,
              userId: widget.userId ?? 0,
            ),
          ),
        );

        await _loadHistoryFromDatabase();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("伺服器錯誤 (${response.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("❌ 後端連線錯誤: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ 連線錯誤：$e")));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // ================================================================
  // 🕒 時間顯示轉換
  // ================================================================
  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "剛剛";
    if (diff.inHours < 1) return "${diff.inMinutes} 分鐘前";
    if (diff.inHours < 24) return "${diff.inHours} 小時前";
    return "${diff.inDays} 天前";
  }

  // ================================================================
  // 🧩 UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final historyToShow =
        _showAllHistory ? _filteredHistory : _filteredHistory.take(5).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 上方 Banner
            Container(
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
                    const Text('真假小助手',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
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
            ),

            // 🔹 主體內容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('請幫我查證資訊真假',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('輸入可疑訊息、網址或上傳圖片 / 影片',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // 🔸 文字輸入框
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: '輸入您要查證的內容...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔸 檔案上傳
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        const Text('上傳圖片 / 影片'),
                        const SizedBox(height: 10),
                        if (_selectedFileName != null)
                          Text("已選擇檔案：$_selectedFileName",
                              style: const TextStyle(color: Colors.grey)),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('選擇檔案'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔸 查證按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _sendToBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isAnalyzing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('立即查證',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔍 搜尋列 + 歷史查詢
                  if (_filteredHistory.isNotEmpty) ...[
                    const Text('歷史查詢',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // 🔍 搜尋框
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜尋關鍵字...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🧾 歷史紀錄清單
                    ...historyToShow.map((item) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: ListTile(
                            title: Text(item['query_text'] ?? '無標題'),
                            subtitle: Text(
                              "查詢時間：${_getRelativeTime(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now())}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing:
                                const Icon(Icons.chat, color: AppColors.primaryGreen),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AIchat(
                                    userId: widget.userId ?? 0, // 延續舊對話
                                  ),
                                ),
                              );
                              await _loadHistoryFromDatabase();
                            },
                          ),
                        )),

                    // 🔘 查看全部 / 收起
                    if (_filteredHistory.length > 5)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _showAllHistory = !_showAllHistory),
                          child: Text(_showAllHistory ? '收起' : '查看全部'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
