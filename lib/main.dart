import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/AIacc.dart';
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/search_page.dart';
import 'package:truthliesdetector/screens/collect_page.dart';
import 'package:truthliesdetector/screens/history_page.dart';
import 'package:truthliesdetector/screens/profile_page.dart';
import 'package:truthliesdetector/screens/home_page.dart';
import 'package:truthliesdetector/screens/splash_page.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'package:truthliesdetector/themes/app_drawer.dart';
import 'package:truthliesdetector/screens/settings_page.dart';
import 'package:truthliesdetector/themes/ball.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truths and Lies Detector',
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryGreen,
        ),
        fontFamily: 'NotoSansSC',
        useMaterial3: true,
      ),
      initialRoute: SplashPage.route,
      routes: {
        SplashPage.route: (context) => const SplashPage(),
        LoginPage.route: (context) => const LoginPage(),
        MainLayout.route: (context) => const MainLayout(),
        SearchPage.route: (context) => const SearchPage(),
        CollectPage.route: (context) => const CollectPage(),
        HistoryPage.route: (context) => const HistoryPage(),
        ProfilePage.route: (context) => const ProfilePage(),
        AIchat.route: (context) => const AIchat(initialQuery: ''),
        SettingsPage.route: (context) => const SettingsPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayout extends StatefulWidget {
  static const route = '/main_layout';
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // 新增狀態變數來控制懸浮球的顯示
  bool _showFab = true;

  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    const AIacc(),
    const SearchPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color(0xFF8BA88E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // 導航到設定頁面
              Navigator.of(context).pushNamed(SettingsPage.route);
            },
          ),
        ],
      ),
      drawer: AppDrawer(
        mainGreen: const Color(0xFF8BA88E),
        onItemTapped: _onItemTapped,
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
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
            // 根據 _showFab 狀態來顯示或隱藏懸浮球
            if (_showFab)
              FloatingActionMenu(
                screenshotController: _screenshotController,
                onTap: _onItemTapped,
                // 提供 onClose 回呼函式來隱藏懸浮球
                onClose: () {
                  setState(() {
                    _showFab = false;
                  });
                },
              ),
            
            // 增加一個按鈕來重新顯示懸浮球
            if (!_showFab)
              Positioned(
                bottom: 100,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _showFab = true;
                    });
                  },
                  child: const Icon(Icons.apps),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ⬇️ 自訂導覽列 Widget
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
    Color mainGreen = const Color(0xFF8BA88E);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: mainGreen,
        borderRadius: const BorderRadius.only(
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
              _buildNavItem(Icons.home, "首頁", 0, mainGreen),
              _buildNavItem(Icons.access_time, "發現", 1, mainGreen),
              const SizedBox(width: 60),
              _buildNavItem(Icons.search, "新聞搜尋", 3, mainGreen),
              _buildNavItem(Icons.person, "我的", 4, mainGreen),
            ],
          ),
          Positioned(
            top: -25,
            left: MediaQuery.of(context).size.width / 2 - 45,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: mainGreen, width: 4),
                ),
                child: Center(
                  child: Image.asset("lib/assets/logo2.png", height: 60, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color mainGreen) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(           fontSize: 12,
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
