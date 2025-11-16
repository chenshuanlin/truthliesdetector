import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import '../providers/user_provider.dart';

class Message {
  final String text;
  final String sender; // user | ai | system
  final Uint8List? imageBytes;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageBytes,
  });
}

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
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isTyping = false;
  bool _isFirst = true;

  // API base
  String get apiBase =>
      kIsWeb ? "http://127.0.0.1:5000/api" : "http://10.0.2.2:5000/api";

  // 關鍵字用來判斷是否查證
  final verifyKeywords = [
    "真假",
    "查證",
    "可信",
    "可信度",
    "來源",
    "真的假的",
    "詐騙",
    "假新聞",
    "謠言",
    "real",
    "fake",
    "fact",
  ];

  @override
  void initState() {
    super.initState();
    _sendInitial();
  }

  // 初次訊息（必定查證）
  void _sendInitial() {
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

  bool _needVerify(String txt) {
    if (_isFirst) return true;
    return verifyKeywords.any((kw) => txt.contains(kw));
  }

  // 核心：送給後端 API
  Future<void> _sendToAI(String text, {Uint8List? image}) async {
    setState(() => _isTyping = true);
    _scrollDown();

    int? userId;
    try {
      userId = Provider.of<UserProvider>(
        context,
        listen: false,
      ).currentUser?.userId;
    } catch (_) {}

    bool doVerify = _needVerify(text) || image != null;

    final url = doVerify
        ? "$apiBase/chat" //
        : "$apiBase/chat/text";

    final body = {"message": text, "user_id": userId};

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

        // ---------- 查證路徑 ----------
        if (doVerify) {
          final combined = data["gemini_result"]["scores"]["combined"];
          String level = combined["level"] ?? "未知";
          double score = (combined["score"] ?? 0.0).toDouble();

          // Step 1: 顯示可信度框
          _messages.add(
            Message(
              text: "可信度：$level（${score.toStringAsFixed(2)}）",
              sender: "system",
              timestamp: DateTime.now(),
            ),
          );

          // Step 2: AI 回覆
          String reply = data["gemini_result"]["reply"] ?? "（AI 無回覆）";
          _messages.add(
            Message(text: reply, sender: "ai", timestamp: DateTime.now()),
          );
        }
        // ---------- 聊天路徑 ----------
        else {
          String reply = data["reply"] ?? "（AI 無回覆）";
          _messages.add(
            Message(text: reply, sender: "ai", timestamp: DateTime.now()),
          );
        }
      } else {
        _messages.add(
          Message(
            text: "後端錯誤：${resp.statusCode}",
            sender: "ai",
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      _messages.add(
        Message(
          text: "⚠️ 無法連線後端，請確認伺服器狀態。",
          sender: "ai",
          timestamp: DateTime.now(),
        ),
      );
    }

    _isFirst = false;
    setState(() => _isTyping = false);
    _scrollDown();
  }

  // 使用者送出訊息
  void _send() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    _messages.add(
      Message(text: txt, sender: "user", timestamp: DateTime.now()),
    );
    _controller.clear();
    _scrollDown();

    _sendToAI(txt);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _bubble(_messages[index]);
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("AI 正在輸入…"),
                  );
                }
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 美化後的對話框
  // ------------------------------------------------------------
  Widget _bubble(Message msg) {
    final isUser = msg.sender == "user";
    final isSystem = msg.sender == "system";

    Color bubbleColor = isUser ? AppColors.primaryGreen : Colors.white;
    if (isSystem) bubbleColor = Colors.yellow.shade200;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(6),
            bottomRight: isUser
                ? const Radius.circular(6)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (msg.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(msg.imageBytes!, height: 150),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
                color: isUser ? Colors.white : Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${msg.timestamp.hour.toString().padLeft(2, "0")}:${msg.timestamp.minute.toString().padLeft(2, "0")}",
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black45,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 輸入列
  // ------------------------------------------------------------
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "輸入訊息…",
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryGreen,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }
}
