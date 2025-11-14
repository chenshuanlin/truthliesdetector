import 'package:flutter/material.dart';

// 導入您專案中需要導航的頁面
// 請確保這些檔案存在於您的專案路徑中

/// 側邊抽屜選單
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.mainGreen,
    required this.onItemTapped,
  });

  final Color mainGreen;
  final Function(int) onItemTapped;

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
                      "lib/assets/logo2.png",
                      height: 60,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 功能選單
              // 點擊「首頁」時，關閉抽屜選單並切換到主頁
              _buildDrawerItem(
                context,
                Icons.home,
                "首頁",
                () => onItemTapped(0),
              ),
              // 點擊「新聞搜尋」時，關閉抽屜選單並切換到新聞搜尋頁面
              _buildDrawerItem(
                context,
                Icons.search,
                "新聞搜尋",
                () => onItemTapped(3),
              ),
              // 點擊「AI助手」時，關閉抽屜選單並切換到 AI助手頁面
              _buildDrawerItem(
                context,
                Icons.smart_toy,
                "AI助手",
                () => onItemTapped(2),
              ),
              // 點擊「用戶資訊」時，關閉抽屜選單並切換到用戶資訊頁面
              _buildDrawerItem(
                context,
                Icons.person,
                "用戶資訊",
                () => onItemTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build a menu item
  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        onTap();
        Navigator.of(context).pop(); // 關閉抽屜
      },
    );
  }
}
