import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/search_page.dart';
import 'package:truthliesdetector/screens/collect_page.dart';
import 'package:truthliesdetector/screens/history_page.dart';
import 'package:truthliesdetector/screens/profile_page.dart';
import 'package:truthliesdetector/screens/home_page.dart';
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/screens/AIchat.dart';

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
      initialRoute: MainLayout.route,
      routes: {
        LoginPage.route: (context) => const LoginPage(),
        MainLayout.route: (context) => const MainLayout(),
        SearchPage.route: (context) => const SearchPage(),
        CollectPage.route: (context) => const CollectPage(),
        HistoryPage.route: (context) => const HistoryPage(),
        ProfilePage.route: (context) => const ProfilePage(),
        AIchat.route: (context) => const AIchat(initialQuery: ''),
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

  // 根據 CustomBottomNavBar 的按鈕順序，調整頁面列表
  // 按鈕順序為：首頁, 發現, AI助手(中間), 新聞搜尋, 我的
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(), // 使用 HistoryPage 作為 "發現" 頁面
    const AIchat(initialQuery: ''),
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
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
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
      height: 60, // 調整高度使其不佔版面
      decoration: BoxDecoration(
        color: mainGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25), // 調整圓角半徑
          topRight: Radius.circular(25), // 調整圓角半徑
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 左右四個選項
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "首頁", 0, mainGreen),
              _buildNavItem(Icons.access_time, "發現", 1, mainGreen),
              const SizedBox(width: 60), // 中間空出位置
              _buildNavItem(Icons.search, "新聞搜尋", 3, mainGreen),
              _buildNavItem(Icons.person, "我的", 4, mainGreen),
            ],
          ),

          // 中間凸起的圓形按鈕
          Positioned(
            top: -25,
            left: MediaQuery.of(context).size.width / 2 - 45,
            child: GestureDetector(
              onTap: () => onTap(2), // index = 2 (AI助手)
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: mainGreen, width: 4),
                ),
                child: Center(
                  // 替換為 logo2.png
                  child: Image.asset("lib/assets/logo2.png", height: 40, fit: BoxFit.contain),
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
