import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ← ★★★ 就是這行你缺少的
import 'package:provider/provider.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import '../providers/user_provider.dart';

// ============================
// 資料結構：訊息
// ============================
class Message {
  final String text;
  final String sender; // "user" or "ai"
  final Uint8List? imageBytes;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageBytes,
  });
}

// ============================
// 主頁面：AIchat
// ============================
class AIchat extends StatefulWidget {
  final String initialQuery;
  final Uint8List? capturedImageBytes;

  static const String route = "/aichat";

  const AIchat({
    super.key,
    required this.initialQuery,
    this.capturedImageBytes,
  });

  @override
  State<AIchat> createState() => _AIchatState();
}

class _AIchatState extends State<AIchat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  bool _isFirstMessage = true; // 第一句一定查證

  String get apiBase =>
      kIsWeb ? "http://127.0.0.1:5000" : "http://10.0.2.2:5000";

  final List<String> verifyKeywords = [
    "真假",
    "查證",
    "可信",
    "可信度",
    "真的假的",
    "是否真",
    "來源",
    "假新聞",
    "詐騙",
    "謠言",
    "fake",
    "real?",
    "fact",
  ];

  @override
  void initState() {
    super.initState();
    _sendInitialMessage();
  }

  void _sendInitialMessage() {
    if (widget.capturedImageBytes != null) {
      _messages.add(
        Message(
          text: "請協助分析這張圖片。",
          sender: "user",
          timestamp: DateTime.now(),
          imageBytes: widget.capturedImageBytes,
        ),
      );
    }

    _messages.add(
      Message(
        text: widget.initialQuery,
        sender: "user",
        timestamp: DateTime.now(),
      ),
    );

    _sendToAI(widget.initialQuery, image: widget.capturedImageBytes);
  }

  bool _needVerify(String text) {
    if (_isFirstMessage) return true;
    return verifyKeywords.any((kw) => text.contains(kw));
  }

  // ============================
  // 發送訊息給後端 /chat
  // ============================
  Future<void> _sendToAI(String text, {Uint8List? image}) async {
    setState(() => _isTyping = true);
    _scrollBottom();

    int? userId;
    try {
      userId = Provider.of<UserProvider>(
        context,
        listen: false,
      ).currentUser?.userId;
    } catch (_) {}

    final url = "$apiBase/chat";

    Map<String, dynamic> body = {"message": text, "user_id": userId};

    if (image != null) {
      body["ai_acc_result"] = {
        "vision_result": {"imageBase64": base64Encode(image)},
      };
    }

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        String reply = data["gemini_result"]?["reply"] ?? "（AI 無回覆）";

        setState(() {
          _messages.add(
            Message(text: reply, sender: "ai", timestamp: DateTime.now()),
          );
        });
      } else {
        setState(() {
          _messages.add(
            Message(
              text: "伺服器錯誤：${resp.statusCode}",
              sender: "ai",
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          Message(
            text: "⚠️ 無法連線後端，請確認伺服器是否啟動。",
            sender: "ai",
            timestamp: DateTime.now(),
          ),
        );
      });
    }

    _isFirstMessage = false;
    setState(() => _isTyping = false);
    _scrollBottom();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _messages.add(
      Message(text: text, sender: "user", timestamp: DateTime.now()),
    );

    _controller.clear();
    _scrollBottom();

    _sendToAI(text);
  }

  // ============================
  // UI BUILD
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          "真假小助手（對話模式）",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _bubble(_messages[index]);
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("AI 正在思考中…"),
                  );
                }
              },
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration.collapsed(
                      hintText: "輸入訊息…",
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryGreen),
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // Chat bubble
  // ============================
  Widget _bubble(Message msg) {
    final isUser = msg.sender == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (msg.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(msg.imageBytes!, height: 150),
              ),
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
