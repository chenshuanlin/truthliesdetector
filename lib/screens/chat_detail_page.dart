import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart';

class ChatDetailPage extends StatelessWidget {
  final String query;
  final Map<String, dynamic> geminiResult;
  final String? createdAt;

  const ChatDetailPage({super.key, required this.query, required this.geminiResult, this.createdAt});

  @override
  Widget build(BuildContext context) {
    final reply = geminiResult['reply'] ?? '';
    final comment = geminiResult['comment'] ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('紀錄詳情', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('問題', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Text(query, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (createdAt != null && createdAt!.isNotEmpty) ...[
              Text('時間', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(createdAt!, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Text('AI 回覆', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Text(reply, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            if (comment != null && comment.isNotEmpty) ...[
              Text('AI 註解', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 6),
              Text(comment, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }
}
