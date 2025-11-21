import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:truthliesdetector/providers/user_provider.dart';

// Screens
import 'package:truthliesdetector/screens/AIacc.dart';
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/register_page.dart';
import 'package:truthliesdetector/screens/search_page.dart';
import 'package:truthliesdetector/screens/collect_page.dart';
import 'package:truthliesdetector/screens/history_page.dart';
import 'package:truthliesdetector/screens/profile_page.dart';
import 'package:truthliesdetector/screens/home_page.dart';
import 'package:truthliesdetector/screens/splash_page.dart';
import 'package:truthliesdetector/screens/AIchat.dart';
import 'package:truthliesdetector/screens/ai_report_page.dart';
import 'package:truthliesdetector/screens/settings_page.dart';

// Theme / Widgets
import 'package:truthliesdetector/themes/app_colors.dart';
import 'package:truthliesdetector/themes/app_drawer.dart';
import 'package:truthliesdetector/themes/ball.dart';

// Tools
import 'package:screenshot/screenshot.dart';
import 'package:truthliesdetector/route_observer.dart'; // ★★★ 必須加這個

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'Truths and Lies Detector',
        debugShowCheckedModeBanner: false,

        // ★★★ 使用 routeObserver
        navigatorObservers: [routeObserver],

        theme: ThemeData(
          primaryColor: AppColors.primaryGreen,
          colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
          fontFamily: 'NotoSansSC',
          useMaterial3: true,
        ),

        initialRoute: SplashPage.route,

        routes: {
          SplashPage.route: (_) => const SplashPage(),
          LoginPage.route: (_) => const LoginPage(),
          RegisterPage.route: (_) => const RegisterPage(),
          MainLayout.route: (_) => const MainLayout(),
          SearchPage.route: (_) => const SearchPage(),
          CollectPage.route: (_) => const CollectPage(),
          HistoryPage.route: (_) => const HistoryPage(),
          ProfilePage.route: (_) => const ProfilePage(),

          // ❗ 不能 const — AIchat 需要參數
          AIchat.route: (_) => AIchat(initialQuery: ""),

          // ChatDetailPage 是動態，不走 named route
          "/chat_detail": (_) => const Placeholder(),

          AiReportPage.route: (_) => const AiReportPage(),
          SettingsPage.route: (_) => const SettingsPage(),
        },
      ),
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

  bool _showFab = true;

  final List<Widget> _pages = [
    const HomePage(), // 0
    const AiReportPage(), // 1
    const AIacc(), // 2
    const SearchPage(), // 3
    const ProfilePage(), // 4
  ];

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
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
                  onPressed: () => setState(() => _showFab = true),
                  child: const Icon(Icons.apps),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
    const Color mainGreen = Color(0xFF8BA88E);

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
              _item(Icons.home, "首頁", 0),
              _item(Icons.access_time, "發現", 1),
              const SizedBox(width: 60),
              _item(Icons.search, "新聞搜尋", 3),
              _item(Icons.person, "我的", 4),
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
                  child: Image.asset(
                    "lib/assets/logo2.png",
                    height: 60,
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

  Widget _item(IconData icon, String label, int index) {
    bool active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
