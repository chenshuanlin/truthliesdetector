import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';

class AIaccScreen extends StatefulWidget {
  static const String route = '/aiacc';

  // 🔹 支援從 main.dart 傳 callback
  final Function(String convId, Map<String, dynamic> backendResult, String query)? onSendToChat;

  const AIaccScreen({super.key, this.onSendToChat});

  @override
  State<AIaccScreen> createState() => _AIaccScreenState();
}

class _AIaccScreenState extends State<AIaccScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isAnalyzing = false;

  List<Map<String, dynamic>> _history = [];

  final String apiBase =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5000');

  // 🔹 選取檔案
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFileBytes = result.files.single.bytes;
        });
      } else {
        setState(() {
          _selectedFileName = null;
          _selectedFileBytes = null;
        });
      }
    } catch (e) {
      debugPrint("檔案選擇錯誤: $e");
    }
  }

  // 🔹 呼叫後端 /analyze
  Future<void> _sendToBackend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入文字或上傳檔案！")),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$apiBase/analyze'));
      request.fields['input'] = text;

      if (_selectedFileBytes != null && _selectedFileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedFileBytes!,
          filename: _selectedFileName!,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        setState(() {
          _history.insert(0, {
            'query': text.isNotEmpty ? text : _selectedFileName,
            'result': result,
            'timestamp': DateTime.now(),
          });
        });

        // 🔹 儲存紀錄 & 通知上層（MainLayout）
        if (widget.onSendToChat != null) {
          widget.onSendToChat!(
            DateTime.now().millisecondsSinceEpoch.toString(),
            result,
            text.isEmpty ? _selectedFileName ?? '' : text,
          );
        }

        // 🔹 導向 AIchat 顯示分析結果
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIchat(
              initialQuery: text.isEmpty ? _selectedFileName ?? '' : text,
              backendResult: result,
              capturedImageBytes: _selectedFileBytes,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("伺服器錯誤 (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 連線錯誤：$e")),
      );
    } finally {
      setState(() => _isAnalyzing = false);
      _textController.clear();
      _selectedFileName = null;
      _selectedFileBytes = null;
    }
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "剛剛";
    if (diff.inHours < 1) return "${diff.inMinutes} 分鐘前";
    if (diff.inHours < 24) return "${diff.inHours} 小時前";
    return "${diff.inDays} 天前";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ 上方區塊
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
            ),

            // ✅ 查證區
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('請幫我查證資訊真假',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('輸入可疑訊息、網址或上傳圖片/影片',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // 輸入框
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

                  // 上傳檔案
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
                        const Text('上傳圖片 / 檔案'),
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
                          child: const Text('選擇文件'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 立即查證
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _sendToBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isAnalyzing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '立即查證',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 歷史紀錄
                  if (_history.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('歷史查詢',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ..._history.take(5).map((item) => Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              child: ListTile(
                                title: Text(item['query'] ?? '無標題'),
                                subtitle: Text(
                                  "查詢時間：${_getRelativeTime(item['timestamp'])}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AIchat(
                                        initialQuery: item['query'] ?? '',
                                        backendResult: item['result'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
