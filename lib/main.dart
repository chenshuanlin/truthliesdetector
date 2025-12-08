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

/// 🌍 系統懸浮球入口
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
// App
// =========================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truths and Lies Detector',
      debugShowCheckedModeBanner: false,
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

        AIacc.route: (_) => const AIacc(),
        AIchat.route: (_) => const AIchat(initialQuery: ""),
      },

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
// 主畫面
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

  // 🔥 避免 overlayListener 重複 listen (修正你的 bug)
  static bool _overlaySubscribed = false;

  late final List<Widget> _pages = [
    const HomePage(),
    const AiReportPage(),
    const AIacc(),
    const SearchPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    if (!_overlaySubscribed) {
      _overlaySubscribed = true;
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
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  // ======================
  // 懸浮球控制
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

  // =====================================================
  // ⭐⭐ 這裡是你要的 AppBar：空白 + 鈴鐺 icon（舊版 UI）
  // =====================================================
  PreferredSizeWidget _buildOldAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryGreen,
      elevation: 0,
      title: const Text(""), // 空白標題

      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            // 點鈴鐺→彈出選單控制懸浮球
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bubble_chart),
                      title: const Text("啟動懸浮球"),
                      onTap: () {
                        Navigator.pop(context);
                        _startGlobalFloatingBall();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text("關閉懸浮球"),
                      onTap: () {
                        Navigator.pop(context);
                        _stopGlobalFloatingBall();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  // =====================================================
  // Scaffold
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildOldAppBar(), // ← 使用舊版 AppBar

      drawer: AppDrawer(
        mainGreen: AppColors.primaryGreen,
        onItemTapped: _onItemTapped,
      ),

      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _pages),

            CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
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
// 自訂底部導航列（完全未修改）
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, "首頁", 0),
                _navItem(Icons.access_time, "發現", 1),
                const SizedBox(width: 60),
                _navItem(Icons.search, "新聞搜尋", 3),
                _navItem(Icons.person, "我的", 4),
              ],
            ),

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
