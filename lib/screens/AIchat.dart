import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'dart:typed_data';

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
  final String initialQuery;
  final Uint8List? capturedImageBytes;
  final Map<String, dynamic>? backendResult;

  static const String route = '/aichat';

  const AIchat({
    super.key,
    required this.initialQuery,
    this.capturedImageBytes,
    this.backendResult,
  });

  @override
  State<AIchat> createState() => _AIchatState();
}

class _AIchatState extends State<AIchat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  /// ✅ Flask 後端 API base
  static const String _apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:5000');

  @override
  void initState() {
    super.initState();
    _handleInitialMessage();
  }

  void _handleInitialMessage() {
    if (widget.capturedImageBytes != null) {
      _messages.add(Message(
        text: '這是我的圖片，請幫我分析。',
        sender: 'user',
        timestamp: DateTime.now(),
        imageBytes: widget.capturedImageBytes,
      ));
    }

    _messages.add(Message(
      text: widget.initialQuery,
      sender: 'user',
      timestamp: DateTime.now(),
    ));

    if (widget.backendResult != null) {
      final formatted = _formatBackendReport(widget.backendResult!);
      _messages.add(Message(
        text: formatted,
        sender: 'ai',
        timestamp: DateTime.now(),
      ));
    } else {
      _sendToBackend(widget.initialQuery, imageBytes: widget.capturedImageBytes);
    }
  }

  /// ✅ 將 AIacc 結果整理成可讀格式
  String _formatBackendReport(Map<String, dynamic> data) {
    try {
      final aiAcc = data['ai_acc_result'] ?? data;
      final gemini = data['gemini_result'] ?? {};

      final score = aiAcc['score'] ?? aiAcc['credibility_score'] ?? '—';
      final level = aiAcc['level'] ?? aiAcc['可信度'] ?? '未知';
      final summary = aiAcc['summary'] ?? gemini['summary'] ?? '';

      return '''
【AI 分析結果】
可信度：$level
分數：$score

${summary.isNotEmpty ? 'AI 結論：$summary' : ''}
''';
    } catch (_) {
      return '⚠️ 無法解析分析結果。';
    }
  }

  /// ✅ 將文字或圖片發送給後端 Gemini 聊天接口
  Future<void> _sendToBackend(String message, {Uint8List? imageBytes}) async {
    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final uri = Uri.parse('$_apiBase/chat');

      http.Response response;

      if (imageBytes != null) {
        // 若有圖片則使用 multipart/form-data
        final request = http.MultipartRequest('POST', uri)
          ..fields['message'] = message
          ..files.add(http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'uploaded_image.png',
          ));

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // 純文字訊息使用 JSON 格式（防止 415 錯誤）
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message}),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiReply = data['reply'] ?? data['response'] ?? "AI 沒有回應內容。";

        setState(() {
          _messages.add(Message(
            text: aiReply,
            sender: 'ai',
            timestamp: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(Message(
            text: "⚠️ 後端伺服器錯誤 (${response.statusCode})",
            sender: 'ai',
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(Message(
          text: "❌ 無法連線後端伺服器：$e",
          sender: 'ai',
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(Message(
        text: text.trim(),
        sender: 'user',
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
    _sendToBackend(text.trim());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 分析結果介面',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index], context);
                } else {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      child: Text(
                        "AI 正在輸入中...",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.userGray,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration:
                    const InputDecoration.collapsed(hintText: '輸入訊息...'),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryGreen),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, BuildContext context) {
    final bool isUser = message.sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : AppColors.lightGreenBG,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft:
                isUser ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight:
                isUser ? const Radius.circular(0) : const Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    message.imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.darkText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isUser ? Colors.white70 : AppColors.darkText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
