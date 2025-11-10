import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:truthliesdetector/themes/app_colors.dart';

/// 訊息結構
class Message {
  final String text;
  final String sender; // 'user' 或 'ai'
  final DateTime timestamp;
  final Uint8List? imageBytes;

  Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageBytes,
  });
}

class AIchat extends StatefulWidget {
  final String? initialQuery;
  final Uint8List? capturedImageBytes;
  final Map<String, dynamic>? backendResult;
  final int? userId;

  static const String route = '/aichat';

  const AIchat({
    super.key,
    this.initialQuery,
    this.capturedImageBytes,
    this.backendResult,
    this.userId,
  });

  @override
  State<AIchat> createState() => _AIchatState();
}

class _AIchatState extends State<AIchat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  bool _isLoadingHistory = false;
  String? lastGeminiSummary;

  final String apiBase =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5000');

  @override
  void initState() {
    super.initState();
    _setupOverlayListener();

    // 若有新的分析結果則開新對話，否則載入舊紀錄
    if (widget.backendResult != null) {
      _initializeChat();
    } else {
      _loadChatHistoryFromServer();
    }
  }

  // ============================================================
  // 🪄 監聽懸浮球傳來的資料
  // ============================================================
  void _setupOverlayListener() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      try {
        final data = jsonDecode(event);
        if (data['type'] == 'result') {
          final credibility = data['credibility'] ?? '未知';
          final summary = data['summary'] ?? '無摘要';
          setState(() {
            _messages.add(Message(
              text: "🟢 懸浮球查證結果\n可信度：$credibility\n$summary",
              sender: 'ai',
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        }
      } catch (e) {
        debugPrint("⚠️ 懸浮球資料解析失敗: $e");
      }
    });
  }

  // ============================================================
  // 🧠 初始化新對話
  // ============================================================
  void _initializeChat() {
    if (widget.initialQuery?.isNotEmpty ?? false) {
      _messages.add(Message(
        text: widget.initialQuery!,
        sender: 'user',
        timestamp: DateTime.now(),
        imageBytes: widget.capturedImageBytes,
      ));
    }

    if (widget.backendResult != null) {
      final msg = _formatAIMessage(widget.backendResult!);
      _messages.add(Message(
        text: msg,
        sender: 'ai',
        timestamp: DateTime.now(),
      ));
      lastGeminiSummary = msg;
    }
  }

  // ============================================================
  // 📜 載入歷史紀錄（延續上次對話）
  // ============================================================
  Future<void> _loadChatHistoryFromServer() async {
    final userId = widget.userId ?? 0;
    setState(() => _isLoadingHistory = true);

    try {
      final response = await http.get(
        Uri.parse('$apiBase/chat/history?user_id=$userId&limit=30'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final records = List<Map<String, dynamic>>.from(data['records'] ?? []);

        setState(() {
          _messages.clear();
          for (final item in records.reversed) {
            final query = item['query_text'] ?? '';
            final aiResult = item['gemini_result'] ?? {};
            final reply = aiResult['reply'] ?? '';
            final createdAt =
                DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

            if (query.isNotEmpty) {
              _messages.add(Message(
                text: query,
                sender: 'user',
                timestamp: createdAt,
              ));
            }
            if (reply.isNotEmpty) {
              _messages.add(Message(
                text: reply,
                sender: 'ai',
                timestamp: createdAt,
              ));
            }
          }
        });
      } else {
        debugPrint('⚠️ 載入聊天紀錄失敗 (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ 載入聊天紀錄錯誤：$e');
    }

    setState(() => _isLoadingHistory = false);
  }

  // ============================================================
  // 🧩 整理 AI 回覆訊息
  // ============================================================
  String _formatAIMessage(Map<String, dynamic> result) {
    if (result.containsKey('gemini_result')) {
      final gemini = result['gemini_result'];
      final reply = gemini['reply'] ?? '';
      final comment = gemini['comment'] ?? '';
      final mode = gemini['mode'] ?? '文字';
      final scores = gemini['scores'] ?? {};

      final combined = scores['combined'] ?? {};
      final text = scores['text'] ?? {};
      final vision = scores['vision'] ?? {};

      final combinedScore = combined['score']?.toString() ?? '—';
      final combinedLevel = combined['level'] ?? '未知';
      final textLevel = text['level'] ?? '未知';
      final visionLevel = vision['level'] ?? '未知';

      return '''
🧠 Gemini 分析模式：$mode
📊 綜合可信度：$combinedLevel（$combinedScore）
📝 文字可信度：$textLevel
📷 圖片可信度：$visionLevel

$reply
$comment
''';
    } else {
      final credibility = result['credibility_level'] ?? result['level'] ?? '未知';
      final score = result['score']?.toString() ?? '—';
      final summary = result['summary'] ?? result['reason'] ?? '無摘要';
      return '''
🖋 可信度分析結果
【可信度】：$credibility（$score）
$summary
''';
    }
  }

  // ============================================================
  // ✉️ 傳送訊息（Gemini 對話延伸）
  // ============================================================
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: text,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
      _textController.clear();
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$apiBase/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId ?? 0,
          'message': text,
          'context': lastGeminiSummary ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final aiMsg = _formatAIMessage(result);

        setState(() {
          _messages.add(Message(
            text: aiMsg,
            sender: 'ai',
            timestamp: DateTime.now(),
          ));
          lastGeminiSummary = aiMsg;
        });
      } else {
        _messages.add(Message(
          text: "⚠️ 對話失敗 (${response.statusCode})，請稍後再試。",
          sender: 'ai',
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.add(Message(
        text: "❌ 無法連線至伺服器：$e",
        sender: 'ai',
        timestamp: DateTime.now(),
      ));
    }

    _scrollToBottom();
  }

  // ============================================================
  // 🔽 自動滾動到底
  // ============================================================
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // 💬 UI：訊息泡泡
  // ============================================================
  Widget _buildMessageBubble(Message msg) {
    final isUser = msg.sender == 'user';
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser ? AppColors.primaryGreen : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 320),
          child: msg.imageBytes != null
              ? Column(
                  crossAxisAlignment: align,
                  children: [
                    Image.memory(msg.imageBytes!, height: 150, fit: BoxFit.cover),
                    const SizedBox(height: 8),
                    Text(msg.text, style: TextStyle(color: textColor, height: 1.5)),
                  ],
                )
              : Text(msg.text, style: TextStyle(color: textColor, height: 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Text(
            _formatTime(msg.timestamp),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        )
      ],
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // 🧩 主畫面
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          'AI 聊天助手',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '輸入訊息...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryGreen),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
