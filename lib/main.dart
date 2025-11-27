import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

// Providers
import 'providers/user_provider.dart';

// Screens
import 'screens/splash_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';
import 'screens/search_page.dart';
import 'screens/collect_page.dart';
import 'screens/history_page.dart';
import 'screens/profile_page.dart';
import 'screens/AIacc.dart';
import 'screens/AIchat.dart';
import 'screens/ai_report_page.dart';
import 'screens/settings_page.dart';

// UI
import 'themes/app_colors.dart';
import 'themes/app_drawer.dart';
import 'themes/ball.dart';

// Route observer
import 'route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(create: (_) => UserProvider(), child: const MyApp()),
  );
}

/// 🌍 系統懸浮球入口 — 額外 entry point（Android）
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: FloatingActionMenu()),
      ),
    ),
  );
}

// =========================================================
// App 主體
// =========================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truths and Lies Detector',
      debugShowCheckedModeBanner: false,

      // ★ 使用 Route Observer（紀錄頁面切換）
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
        AiReportPage.route: (_) => const AiReportPage(),
        SettingsPage.route: (_) => const SettingsPage(),

        // AIacc 不能 const（但 constructor 本身可 const）
        AIacc.route: (_) => const AIacc(),

        // AIchat 必須提供 initialQuery
        AIchat.route: (_) => const AIchat(initialQuery: ""),
      },

      // ★ onGenerateRoute for dynamic pages
      onGenerateRoute: (settings) {
        if (settings.name == "/chat_detail") {
          return MaterialPageRoute(builder: (_) => const Placeholder());
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

  // 新版 B 底部導覽頁面
  late final List<Widget> _pages = [
    const HomePage(), // 0 首頁
    const AiReportPage(), // 1 發現（AI 報告）
    const AIacc(), // 2 AI 查證（中間圓形按鈕）
    const SearchPage(), // 3 新聞搜尋
    const ProfilePage(), // 4 我的
  ];

  @override
  void initState() {
    super.initState();

    // 監聽 Android 懸浮球事件
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event["action"] == "open_page") {
        switch (event["page"]) {
          case "AIacc":
            if (_currentIndex != 2) setState(() => _currentIndex = 2);
            break;
          case "SearchPage":
            if (_currentIndex != 3) setState(() => _currentIndex = 3);
            break;
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  // ======================
  // 啟動 Android 懸浮球
  // ======================
  Future<void> _startGlobalFloatingBall() async {
    if (kIsWeb) return;

    bool granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      granted = await FlutterOverlayWindow.requestPermission() ?? false;
    }

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("請授權懸浮窗權限才能啟動")));
      }
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "TruthLiesDetector",
      overlayContent: "AI懸浮球啟動中...",
      height: 120,
      width: 120,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPrivate,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ 懸浮球已啟動")));
    }
  }

  // ======================
  // 關閉懸浮球
  // ======================
  Future<void> _stopGlobalFloatingBall() async {
    if (kIsWeb) return;

    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🛑 懸浮球已關閉")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('真偽探測站'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.bubble_chart),
            tooltip: "啟動懸浮球",
            onPressed: _startGlobalFloatingBall,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: "關閉懸浮球",
            onPressed: _stopGlobalFloatingBall,
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
            IndexedStack(index: _currentIndex, children: _pages),

            // 自訂 Bottom Navigation
            CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
            ),

            // App 內懸浮球（可恢復）
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
// 自訂底部導航列（新版 B 版）
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
    const Color mainGreen = Color(0xFF8BA88E);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: mainGreen,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 底部的選項列（首頁、發現、搜尋、我的）
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, "首頁", 0),
                _navItem(Icons.access_time, "發現", 1),
                const SizedBox(width: 60), // 中間圓形按鈕的空位
                _navItem(Icons.search, "新聞搜尋", 3),
                _navItem(Icons.person, "我的", 4),
              ],
            ),

            // 中間圓形按鈕（AIacc）
            Positioned(
              top: -28,
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
      ),
    );
  }

  // 底部導覽 item
  Widget _navItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;

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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
// =========================================================
// main.dart 結尾（如果有需要補充，可在此加入 Helper 或全域 function）
// =========================================================

// 目前 FloatingActionMenu 定義在 themes/ball.dart
// main.dart 不需重複定義，直接使用即可。

// 🎉 main.dart 完成！
