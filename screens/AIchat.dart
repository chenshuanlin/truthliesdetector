import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'dart:typed_data';

// Message 類別用於定義聊天訊息的結構
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

  static const String route = '/aichat';

  const AIchat({
    super.key,
    required this.initialQuery,
    this.capturedImageBytes,
  });

  @override
  State<AIchat> createState() => _AIchatState();
}

class _AIchatState extends State<AIchat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _handleInitialMessage();
  }

  void _handleInitialMessage() {
    // 檢查是否有傳入圖片，如果有則先顯示圖片
    if (widget.capturedImageBytes != null) {
      _messages.add(Message(
        text: '這是我的截圖，請幫我分析。',
        sender: 'user',
        timestamp: DateTime.now(),
        imageBytes: widget.capturedImageBytes,
      ));
    }
    
    // 將初始訊息添加到聊天記錄中
    _messages.add(Message(
      text: widget.initialQuery,
      sender: 'user',
      timestamp: DateTime.now(),
    ));

    // 發送初始查詢給 AI
    _sendToAI(widget.initialQuery, imageBytes: widget.capturedImageBytes);
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

  Future<void> _sendToAI(String message, {Uint8List? imageBytes}) async {
    setState(() => _isTyping = true);
    _scrollToBottom();

    // 將圖片轉換為 Base64 字串以用於 API 請求
    String? base64Image;
    if (imageBytes != null) {
      base64Image = base64Encode(imageBytes);
    }
    
    final apiKey = ''; // 在執行環境中會自動提供
    final apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=$apiKey';

    // 構建 API 請求的內容
    final List<Map<String, dynamic>> parts = [
      {'text': message},
    ];
    if (base64Image != null) {
      parts.add({
        'inlineData': {
          'mimeType': 'image/png', // 假設圖片格式為 png
          'data': base64Image,
        }
      });
    }

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        }
      ],
      'tools': [
        {'google_search': {}}
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String aiReply = data['candidates'][0]['content']['parts'][0]['text'] ?? '抱歉，我無法理解您的意思。';
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
            text: '抱歉，目前無法連接到 AI 服務。',
            sender: 'ai',
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(Message(
          text: '網路錯誤，請檢查您的連線。',
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
    _textController.clear();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: text,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _sendToAI(text);
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
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index], context);
                } else {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'AI 正在輸入...',
                        style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.userGray),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
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
              children: <Widget>[
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
                      decoration: const InputDecoration.collapsed(
                        hintText: '輸入訊息...',
                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, BuildContext context) {
    final bool isUser = message.sender == 'user';
    double maxWidthMultiplier = 0.75;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * maxWidthMultiplier,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : AppColors.lightGreenBG,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15),
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
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
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
