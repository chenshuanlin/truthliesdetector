import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../route_observer.dart';

// 假設這些檔案已存在於您的專案中
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'chat_detail_page.dart';

class AIacc extends StatefulWidget {
  static const String route = '/aiacc'; // ✅ route 名稱

  const AIacc({super.key});

  @override
  State<AIacc> createState() => _AIaccState();
}

class _AIaccState extends State<AIacc> with RouteAware {
  final TextEditingController _textController = TextEditingController();
  String? _selectedFileName;
  List<Map<String, dynamic>> _historyQueries = [];
  bool _isLoadingHistory = false;
  bool _userListenerAttached = false;
  bool _expandedHistory = false;

  void _onUserChanged() {
    // reload when user login state changes
    if (mounted) {
      _loadHistoryQueries();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistoryQueries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
    // attach a listener to UserProvider so we reload history when login state changes
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!_userListenerAttached) {
        userProvider.addListener(_onUserChanged);
        _userListenerAttached = true;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      routeObserver.unsubscribe(this);
      if (_userListenerAttached) {
        try {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          userProvider.removeListener(_onUserChanged);
        } catch (_) {}
        _userListenerAttached = false;
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh when returning from chat page
    _loadHistoryQueries();
  }

  Future<void> _loadHistoryQueries() async {
    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
        _historyQueries = [];
      });
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId ?? 0;
      if (userId == 0) {
        // not logged in
        if (mounted) setState(() => _historyQueries = []);
        return;
      }

      final apiBase = kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000';
      final url = '$apiBase/chat/history?user_id=$userId&limit=10';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final records = List<Map<String, dynamic>>.from(data['records'] ?? []);
        final mapped = records.map((r) {
          final query = (r['query'] ?? '').toString();
          final createdAt = (r['created_at'] ?? '').toString();
          final gemini = r['gemini_result'] ?? {};
          final combinedLevel = gemini is Map && gemini['scores'] != null
              ? (gemini['scores']['combined']?['level'] ?? '')
              : (r['ai_acc_result']?['level'] ?? '');
          final mode = gemini is Map ? (gemini['mode'] ?? '') : '';

          return {
            'title': query.length > 80 ? '${query.substring(0, 80)}...' : query,
            'time': createdAt,
            'status': mode == '' ? '已查證' : mode,
            'confidence': combinedLevel ?? '未知',
            // keep full payload for detail view
            'query_full': query,
            'gemini': gemini,
            'created_at': createdAt,
          };
        }).toList();

        if (mounted)
          setState(
            () => _historyQueries = List<Map<String, dynamic>>.from(mapped),
          );
      } else {
        print('歷史查詢 API 回應錯誤: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('歷史查詢錯誤: $e');
      if (mounted) setState(() => _historyQueries = []);
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // 處理文件選擇
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() => _selectedFileName = result.files.single.name);
      } else {
        setState(() => _selectedFileName = null);
      }
    } catch (e) {
      print('檔案選擇錯誤: $e');
    }
  }

  // 導航到 AIchat 頁面
  void _navigateToChat() {
    String queryMessage = _textController.text.trim();
    String messageToSend;

    if (_selectedFileName != null && queryMessage.isNotEmpty) {
      messageToSend = '請查證此訊息："$queryMessage" 並分析檔案: "$_selectedFileName"';
    } else if (_selectedFileName != null) {
      messageToSend = '請查證檔案: "$_selectedFileName"';
    } else if (queryMessage.isNotEmpty) {
      messageToSend = '請查證此訊息："$queryMessage"';
    } else {
      // 如果沒有輸入文字也沒有選擇檔案，可以給一個預設訊息或提示
      messageToSend = '請查證...';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIchat(initialQuery: messageToSend),
      ),
    );

    // 導航後清空輸入框和選定的檔案
    _textController.clear();
    setState(() => _selectedFileName = null);
  }

  // 取得可信度標籤的顏色
  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case '高可信度':
        return Colors.green.shade700;
      case '中可信度':
        return Colors.orange.shade700;
      case '低可信度':
      default:
        return Colors.red.shade700;
    }
  }

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
            // ✅ 頂部區域 - 介紹與返回按鈕
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0, left: 16.0),
                      child: InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        //child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
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
                          // 注意: 這裡使用了本機圖片，請確保您的 assets 中有此圖片
                          child: Image.asset(
                            'lib/assets/logo2.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ 主要輸入區域
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '請幫您查證資訊真假',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '輸入可疑訊息、網址或上傳圖片/影片',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // ✅ 訊息輸入框
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: const InputDecoration.collapsed(
                        hintText: '  請輸入您要查證的訊息內容或網址... ',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ 上傳檔案區域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('上傳圖片/影片', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        if (_selectedFileName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              '已選擇檔案: $_selectedFileName',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('選擇文件'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ✅ 查證按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        '立即查證',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ✅ 歷史紀錄區塊
                  if (_isLoadingHistory)
                    const Center(child: CircularProgressIndicator())
                  else if (_historyQueries.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          '沒有歷史查詢資料',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '歷史查詢',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                print('查看所有歷史查詢');
                              },
                              child: const Text(
                                '查看全部',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _expandedHistory
                              ? _historyQueries.length
                              : (_historyQueries.length > 3
                                    ? 3
                                    : _historyQueries.length),
                          itemBuilder: (context, index) {
                            final query = _historyQueries[index];
                            final title = (query['title'] ?? '').toString();
                            final status = (query['status'] ?? '').toString();
                            final time = (query['time'] ?? '').toString();
                            final confidence = (query['confidence'] ?? '')
                                .toString();
                            return InkWell(
                              onTap: () {
                                // navigate to detail page showing full previous chat
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(
                                      query: query['query_full'] ?? title,
                                      geminiResult: Map<String, dynamic>.from(
                                        query['gemini'] ?? {},
                                      ),
                                      createdAt: query['created_at'] ?? time,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                time,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            confidence,
                                            style: TextStyle(
                                              color: _getConfidenceColor(
                                                confidence,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_historyQueries.length > 3)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () => setState(
                                () => _expandedHistory = !_expandedHistory,
                              ),
                              child: Text(_expandedHistory ? '顯示較少' : '顯示全部'),
                            ),
                          ),
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
