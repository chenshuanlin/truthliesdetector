import 'package:flutter/material.dart';

/// 側邊抽屜選單
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.mainGreen,
  });

  final Color mainGreen;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: mainGreen,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      // 確保路徑與 pubspec.yaml 中設定的完全一致
                      "assets/logo.png",
                      height: 60,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 功能選單
              _buildDrawerItem(context, Icons.home, "首頁"),
              _buildDrawerItem(context, Icons.search, "新聞搜尋"),
              _buildDrawerItem(context, Icons.smart_toy, "AI助手"),
              _buildDrawerItem(context, Icons.person, "用戶資訊"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.of(context).pop();
        // TODO: 根據點擊的項目導航到不同的頁面
      },
    );
  }
}
