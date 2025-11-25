import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'package:truthliesdetector/themes/app_colors.dart';

/// 訊息結構
class Message {
  final String text;
  final String sender; // 'user' | 'ai' | 'system'
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
  final Map<String, dynamic>? backendResult; // 🔥 查證傳入
  final int? userId; // 🔥 用於載入聊天紀錄

  static const String route = "/aichat";

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
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _isLoadingHistory = false;

  String? lastGeminiSummary;

  // API base URL
  final String apiBase =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5000/api');

  @override
  void initState() {
    super.initState();

    _setupOverlayListener();

    if (widget.backendResult != null) {
      // 有新的查證結果 → 開啟新對話
      _initNewChatWithResult();
    } else {
      // 無查證結果 → 載入舊紀錄
      _loadChatHistory();
    }
  }

  // ------------------------------------------------------------
  // 🔥 懸浮球事件監聽
  // ------------------------------------------------------------
  void _setupOverlayListener() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      try {
        final data = jsonDecode(event);

        if (data["type"] == "result") {
          final credibility = data['credibility'] ?? "未知";
          final summary = data['summary'] ?? "無摘要";

          _messages.add(
            Message(
              text: "🟢 懸浮球查證結果\n可信度：$credibility\n$summary",
              sender: "ai",
              timestamp: DateTime.now(),
            ),
          );

          _scrollDown();
        }
      } catch (e) {
        debugPrint("⚠️ 懸浮球資料解析失敗: $e");
      }
    });
  }

  // ------------------------------------------------------------
  // 🔥 新查證結果 → 新對話
  // ------------------------------------------------------------
  void _initNewChatWithResult() {
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _messages.add(
        Message(
          text: widget.initialQuery!,
          sender: "user",
          timestamp: DateTime.now(),
          imageBytes: widget.capturedImageBytes,
        ),
      );
    }

    if (widget.backendResult != null) {
      final replyText = _formatAIResult(widget.backendResult!);

      _messages.add(
        Message(
          text: replyText,
          sender: "ai",
          timestamp: DateTime.now(),
        ),
      );

      lastGeminiSummary = replyText;
    }
  }

  // ------------------------------------------------------------
  // 🔥 從後端載入歷史紀錄
  // ------------------------------------------------------------
  Future<void> _loadChatHistory() async {
    final uid = widget.userId ?? 0;

    setState(() => _isLoadingHistory = true);

    try {
      final resp = await http.get(
        Uri.parse("$apiBase/chat/history?user_id=$uid&limit=30"),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final records = List<Map<String, dynamic>>.from(data["records"] ?? []);

        _messages.clear();
        for (final item in records.reversed) {
          final query = item["query_text"] ?? "";
          final gemini = item["gemini_result"] ?? {};
          final reply = gemini["reply"] ?? "";
          final created =
              DateTime.tryParse(item["created_at"] ?? "") ?? DateTime.now();

          if (query.isNotEmpty) {
            _messages.add(Message(text: query, sender: "user", timestamp: created));
          }

          if (reply.isNotEmpty) {
            _messages.add(Message(text: reply, sender: "ai", timestamp: created));
          }
        }
      }
    } catch (e) {
      debugPrint("❌ 載入歷史錯誤: $e");
    }

    setState(() => _isLoadingHistory = false);
  }

  // ------------------------------------------------------------
  // 🔥 格式化 AI 查證結果
  // ------------------------------------------------------------
  String _formatAIResult(Map<String, dynamic> r) {
    if (r.containsKey("gemini_result")) {
      final g = r["gemini_result"];
      final mode = g["mode"] ?? "文字";

      final scores = g["scores"] ?? {};
      final combined = scores["combined"] ?? {};

      return """
🧠 Gemini 模式：$mode
📊 綜合可信度：${combined["level"] ?? "未知"}（${combined["score"] ?? "—"}）

${g["reply"] ?? ""}
${g["comment"] ?? ""}
""";
    }

    // fallback: 舊格式
    return """
📊 可信度：${r["level"] ?? "未知"}（${r["score"] ?? "—"}）
${r["summary"] ?? ""}
""";
  }

  // ------------------------------------------------------------
  // ✉️ 送出訊息 + 延續 Gemini 對話
  // ------------------------------------------------------------
  Future<void> _sendMessage() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    _messages.add(
      Message(text: txt, sender: "user", timestamp: DateTime.now()),
    );
    _controller.clear();
    _scrollDown();

    try {
      final resp = await http.post(
        Uri.parse("$apiBase/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId ?? 0,
          "message": txt,
          "context": lastGeminiSummary ?? "",
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final replyText = _formatAIResult(data);

        _messages.add(
          Message(
            text: replyText,
            sender: "ai",
            timestamp: DateTime.now(),
          ),
        );

        lastGeminiSummary = replyText;
      } else {
        _messages.add(Message(
          text: "⚠️ 伺服器回應錯誤 ${resp.statusCode}",
          sender: "ai",
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.add(Message(
        text: "❌ 連線錯誤：$e",
        sender: "ai",
        timestamp: DateTime.now(),
      ));
    }

    _scrollDown();
  }

  // ------------------------------------------------------------
  // 🔽 自動滾動底部
  // ------------------------------------------------------------
  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ------------------------------------------------------------
  // 💬 氣泡 UI
  // ------------------------------------------------------------
  Widget _bubble(Message msg) {
    final isUser = msg.sender == "user";
    final color = isUser ? AppColors.primaryGreen : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Image.memory(
                  msg.imageBytes!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            Text(msg.text, style: TextStyle(color: textColor, height: 1.4)),
            const SizedBox(height: 4),
            Text(
              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            )
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🧩 主 UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text("AI 聊天助手", style: TextStyle(color: Colors.white)),
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
              controller: _scroll,
              itemCount: _messages.length,
              itemBuilder: (_, i) => _bubble(_messages[i]),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "輸入訊息…",
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
          )
        ],
      ),
    );
  }
}
