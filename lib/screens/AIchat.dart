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

  // 歷史紀錄回顧
  final int? sessionId;
  final List<dynamic>? existingConversation;
  final String? createdAt;
  final String? title;

  static const String route = "/aichat";

  const AIchat({
    super.key,
    required this.initialQuery,
    this.capturedImageBytes,
    this.sessionId,
    this.existingConversation,
    this.createdAt,
    this.title,
  });

  @override
  State<AIchat> createState() => _AIchatState();
}

class _AIchatState extends State<AIchat> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  int? _sessionId;

  String get apiBase =>
      kIsWeb ? "http://127.0.0.1:5000/api" : "http://10.0.2.2:5000/api";

  @override
  void initState() {
    super.initState();

    if (widget.sessionId != null && widget.existingConversation != null) {
      _loadFromHistory();
    } else {
      _startSession();
    }
  }

  // ============================================================
  // A. 從歷史紀錄載入（最完整修正版）
  // ============================================================
  void _loadFromHistory() {
    print("📜 從歷史紀錄載入對話，sessionId = ${widget.sessionId}");
    _sessionId = widget.sessionId;

    final List<dynamic> conv = widget.existingConversation ?? [];

    // ❗ conversation 若為空 → 避免 UI 空白
    if (conv.isEmpty) {
      print("⚠️ 這筆紀錄是空的 conversation");
      _messages.add(
        Message(
          text: "（此查證紀錄沒有內容可顯示）",
          sender: "system",
          timestamp: DateTime.now(),
        ),
      );
      setState(() {});
      _scrollDown();
      return;
    }

    // 正常載入 conversation
    for (final item in conv) {
      if (item is! Map) continue;

      final sender = item["sender"]?.toString() ?? "system";
      final text = item["text"]?.toString() ?? "";
      final tsStr = item["timestamp"]?.toString();

      DateTime ts;
      try {
        ts = tsStr != null ? DateTime.parse(tsStr) : DateTime.now();
      } catch (_) {
        ts = DateTime.now();
      }

      _messages.add(Message(text: text, sender: sender, timestamp: ts));
    }

    setState(() {});
    _scrollDown();
  }

  // ============================================================
  // B. 新對話建立 Session — /chat/start
  // ============================================================
  Future<void> _startSession() async {
    print("🚀 建立新 Session...");

    final userId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).currentUser?.userId;

    final url = "$apiBase/chat/start";

    final body = {"message": widget.initialQuery, "user_id": userId};

    if (widget.capturedImageBytes != null) {
      body["ai_acc_result"] = {
        "vision_result": {
          "imageBase64": base64Encode(widget.capturedImageBytes!),
        },
      };
    }

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("📥 /chat/start 回應：${resp.body}");
      final data = jsonDecode(resp.body);

      _sessionId = data["session_id"];

      // 使用者訊息
      _messages.add(
        Message(
          text: widget.initialQuery,
          sender: "user",
          timestamp: DateTime.now(),
          imageBytes: widget.capturedImageBytes,
        ),
      );

      // System（可信度）
      if (data["ai_acc_result"] != null) {
        final level = data["ai_acc_result"]["level"] ?? "未知";
        final score = data["ai_acc_result"]["score"] ?? 0;

        _messages.add(
          Message(
            text: "可信度：$level（$score）",
            sender: "system",
            timestamp: DateTime.now(),
          ),
        );
      }

      // AI 回覆
      final reply = data["reply"] ?? "(AI 無回覆)";
      _messages.add(
        Message(text: reply, sender: "ai", timestamp: DateTime.now()),
      );

      setState(() {});
      _scrollDown();
    } catch (e) {
      print("❌ /chat/start error: $e");
    }
  }

  // ============================================================
  // C. 續問 — /chat/append
  // ============================================================
  Future<void> _sendAppend(String text) async {
    if (_sessionId == null) {
      print("❌ session_id 為 null");
      return;
    }

    final url = "$apiBase/chat/append";
    final body = {"session_id": _sessionId, "message": text};

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("📥 /chat/append 回應：${resp.body}");
      final data = jsonDecode(resp.body);

      final reply = data["reply"] ?? "(AI 無回覆)";

      _messages.add(
        Message(text: reply, sender: "ai", timestamp: DateTime.now()),
      );

      setState(() {});
      _scrollDown();
    } catch (e) {
      print("❌ /chat/append error: $e");
    }
  }

  // ============================================================
  // 送出使用者訊息
  // ============================================================
  void _send() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    _messages.add(
      Message(text: txt, sender: "user", timestamp: DateTime.now()),
    );

    _controller.clear();
    setState(() {});
    _scrollDown();

    _sendAppend(txt);
  }

  void _scrollDown() {
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

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text(
          "真假小助手",
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
              itemCount: _messages.length,
              itemBuilder: (_, index) => _bubble(_messages[index]),
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  // ============================================================
  // 氣泡
  // ============================================================
  Widget _bubble(Message msg) {
    final isUser = msg.sender == "user";
    final isSystem = msg.sender == "system";

    Color bubbleColor = isUser
        ? AppColors.primaryGreen
        : (isSystem ? Colors.yellow.shade200 : Colors.white);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
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
                color: isUser ? Colors.white : Colors.black87,
                fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
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

  // ============================================================
  // 底部輸入列
  // ============================================================
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
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
