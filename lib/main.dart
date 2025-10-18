import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

// 📂 Screens
import 'package:truthliesdetector/screens/AIacc.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'package:truthliesdetector/screens/home_page.dart';
import 'package:truthliesdetector/screens/profile_page.dart';
import 'package:truthliesdetector/screens/search_page.dart';
import 'package:truthliesdetector/screens/login_page.dart';

// 📂 UI
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/themes/app_drawer.dart';
import 'package:truthliesdetector/themes/ball.dart';

void main() {
  runApp(const MyApp());
}

// =========================================================
// App 主體
// =========================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruthLiesDetector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
        fontFamily: 'NotoSansSC',
        useMaterial3: true,
      ),
      // ✅ 首頁預設為登入頁
      initialRoute: LoginPage.route,
      routes: {
        LoginPage.route: (_) => const LoginPage(),
        MainLayout.route: (_) => const MainLayout(),
      },
      // ✅ AIacc → AIchat 導航帶參數
      onGenerateRoute: (settings) {
        if (settings.name == AIchat.route) {
          final args = (settings.arguments ?? {}) as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AIchat(
              initialQuery: args['initialQuery'] ?? '',
              backendResult: args['backendResult'],
              capturedImageBytes: args['capturedImageBytes'],
            ),
          );
        }
        return null;
      },
    );
  }
}

// =========================================================
// 主畫面（底部導航 + 懸浮球）
// =========================================================
class MainLayout extends StatefulWidget {
  static const String route = '/main_layout';

  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _showFab = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  late final List<Widget> _pages = [
    const HomePage(),
    // 🔹 第二頁：真假小助手（AIacc）
    AIaccScreen(
      onSendToChat: (convId, backendResult, query) {
        Navigator.of(context).pushNamed(
          AIchat.route,
          arguments: {
            'initialQuery': query,
            'backendResult': backendResult,
          },
        );
      },
    ),
    const SearchPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('真偽探測站'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("⚙️ 設定功能開發中...")),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        mainGreen: AppColors.primaryGreen,
        onItemTapped: _onItemTapped,
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onItemTapped,
              ),
            ),
            if (_showFab)
              FloatingActionMenu(
                screenshotController: _screenshotController,
                onTap: _onItemTapped,
                onClose: () => setState(() => _showFab = false),
              ),
            if (!_showFab)
              Positioned(
                bottom: 100,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: AppColors.primaryGreen,
                  onPressed: () => setState(() => _showFab = true),
                  child: const Icon(Icons.apps, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 自訂底部導航列
// =========================================================
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const mainGreen = AppColors.primaryGreen;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: mainGreen,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(Icons.home, "首頁", 0),
              _buildItem(Icons.analytics, "查證", 1),
              const SizedBox(width: 60),
              _buildItem(Icons.search, "搜尋", 2),
              _buildItem(Icons.person, "我的", 3),
            ],
          ),
          // 🔹 中央 Logo 按鈕（快捷進入真假小助手）
          Positioned(
            top: -25,
            left: MediaQuery.of(context).size.width / 2 - 45,
            child: GestureDetector(
              onTap: () => onTap(1),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: mainGreen, width: 4),
                ),
                child: Center(
                  child: Image.asset(
                    "lib/assets/logo2.png",
                    height: 55,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
