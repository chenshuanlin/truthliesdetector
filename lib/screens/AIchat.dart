import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 導入 http 套件
import 'dart:convert'; // 導入 json 轉換
import 'package:truthliesdetector/themes/app_colors.dart'; // 導入自定義顏色
import 'dart:typed_data'; // 導入 Uint8List 類型

// 定義聊天訊息的數據結構
class Message {
  final String text;
  final String sender; // 'user' 或 'ai'
  final DateTime timestamp;
  final Uint8List? imageBytes; // 新增圖片數據字段

  Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageBytes, // 可選的圖片數據
  });
}

class AIcaht extends StatefulWidget { // 類別名稱已更新為 AIcaht
  final String initialQuery; // 從前一個頁面傳過來的初始查詢
  final Uint8List? capturedImageBytes; // 新增接收截圖數據的參數

  const AIcaht({
    super.key,
    required this.initialQuery,
    this.capturedImageBytes, // 初始化截圖數據
  });

  @override
  State<AIcaht> createState() => _AIcahtState(); // 狀態類別名稱已更新
}

class _AIcahtState extends State<AIcaht> { // 狀態類別名稱已更新
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = []; // 聊天訊息列表
  bool _isTyping = false; // AI 是否正在輸入

  @override
  void initState() {
    super.initState();
    // 檢查是否有傳入截圖數據，如果有則先處理圖片消息
    if (widget.capturedImageBytes != null) {
      _messages.add(Message(
        text: '這是我截取的畫面，請幫我辨識。',
        sender: 'user',
        timestamp: DateTime.now(),
        imageBytes: widget.capturedImageBytes, // 添加截圖數據
      ));
      _sendToAI(widget.initialQuery, isInitial: true); // 接著發送初始文字查詢
    } else {
      // 如果沒有截圖，則直接發送初始文字查詢
      _messages.add(Message(
        text: widget.initialQuery,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
      _sendToAI(widget.initialQuery, isInitial: true);
    }
  }

  // 滾動到列表底部
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

  // 發送訊息到 AI (模擬後端互動)
  Future<void> _sendToAI(String message, {bool isInitial = false}) async {
    setState(() {
      _isTyping = true; // AI 正在輸入
    });
    _scrollToBottom(); // 發送後滾動到底部

    try {
      // TODO: 將 'YOUR_AI_BACKEND_API_URL/chat' 替換為實際的 AI 後端 API 端點
      // 這個 API 應該接收使用者訊息並返回 AI 的回覆
      // 範例 POST 請求：
      final response = await http.post(
        Uri.parse('https://api.example.com/chat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        // 成功取得 AI 回覆
        final Map<String, dynamic> data = json.decode(response.body);
        final String aiReply = data['reply'] ?? '抱歉，我無法理解您的意思。'; // 從 JSON 獲取回覆
        setState(() {
          _messages.add(Message(
            text: aiReply,
            sender: 'ai',
            timestamp: DateTime.now(),
          ));
        });
        print('AI 回覆: $aiReply');
      } else {
        // 處理 HTTP 請求失敗的情況
        print('從後端獲取 AI 回覆失敗，狀態碼: ${response.statusCode}');
        setState(() {
          _messages.add(Message(
            text: '抱歉，目前無法連接到 AI 服務。',
            sender: 'ai',
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      // 處理網路錯誤或其他異常
      print('與 AI 互動時發生錯誤: $e');
      setState(() {
        _messages.add(Message(
          text: '網路錯誤，請檢查您的連線。',
          sender: 'ai',
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isTyping = false; // AI 停止輸入
      });
      _scrollToBottom(); // 新訊息加入後滾動到底部
    }

    // 移除了舊的模擬回覆邏輯，因為現在有實際的 HTTP 請求處理
    // 如果您希望在 HTTP 請求失敗時仍有模擬回覆，請將模擬邏輯移到 catch 區塊
  }

  // 處理訊息發送
  void _handleSubmitted(String text) {
    _textController.clear(); // 清空輸入框
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: text,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom(); // 發送後滾動到底部
    _sendToAI(text); // 將訊息發送給 AI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 背景色
      appBar: AppBar(
        toolbarHeight: 80, // 增加 AppBar 高度
        backgroundColor: AppColors.primaryGreen, // 使用自定義顏色
        elevation: 0, // 移除陰影
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white), // 返回箭頭
          onPressed: () {
            Navigator.pop(context); // 返回上一頁
          },
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
              controller: _scrollController, // 連接滾動控制器
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0), // 如果 AI 正在輸入，多加一個項目
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, context);
                } else {
                  // AI 正在輸入的動畫
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
                          bottomLeft: Radius.circular(4), // AI 氣泡左下角直角
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text('AI 正在輸入...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                  );
                }
              },
            ),
          ),
          // 輸入框和發送按鈕
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen, // 使用自定義顏色
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
                      onSubmitted: _handleSubmitted, // 按下 Enter 鍵發送
                      decoration: const InputDecoration.collapsed(
                        hintText: '輸入訊息...',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // 發送按鈕
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
                    icon: Icon(Icons.send, color: AppColors.primaryGreen), // 發送圖標
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

  // 根據訊息發送者構建聊天氣泡
  Widget _buildMessageBubble(Message message, BuildContext context) {
    final bool isUser = message.sender == 'user';
    // 氣泡最大寬度為螢幕的 75%
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
          // 使用 AppColors.primaryGreen for user, Colors.grey.shade200 for AI
          color: isUser ? AppColors.primaryGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15), // Changed from 12 to 15 for consistency with previous AIchat
            topRight: const Radius.circular(15), // Changed from 12 to 15
            bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(0), // User: round, AI: flat bottom left
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(15), // User: flat bottom right, AI: round
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column( // Use Column to stack image and text
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null) // 如果有圖片數據，顯示圖片
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.memory(
                  message.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity, // 讓圖片填滿訊息氣泡寬度
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black, // Text color based on sender
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5), // Added space for timestamp
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54, // Timestamp color based on sender
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
