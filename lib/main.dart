import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

// 📂 Screens
import 'screens/home_page.dart';
import 'screens/AIacc.dart';
import 'screens/profile_page.dart';
import 'screens/search_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/ai_report_page.dart';
import 'screens/settings_page.dart';
import 'screens/collect_page.dart';
import 'screens/history_page.dart';

// 📂 Providers
import 'providers/user_provider.dart';

// 📂 UI
import 'themes/app_colors.dart';
import 'themes/app_drawer.dart';
import 'themes/ball.dart'; // 假設 FloatingActionMenu 在此檔案

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

// 🌍 系統懸浮球入口 (僅 Android)
// 這個函數必須獨立於 main() 並且在檔案的頂部定義
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // 確保懸浮窗有一個可見的 Widget 根
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // 設置為透明，這樣可以只看到 FloatingActionMenu
        backgroundColor: Colors.transparent, 
        body: SafeArea(
          // FloatingActionMenu 應是一個簡單、可見的 Widget
          child: FloatingActionMenu(), 
        ),
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
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
        fontFamily: 'NotoSansSC',
        useMaterial3: true,
      ),
      initialRoute: LoginPage.route,
      routes: {
        LoginPage.route: (_) => const LoginPage(),
        RegisterPage.route: (_) => const RegisterPage(),
        MainLayout.route: (_) => const MainLayout(),
        SettingsPage.route: (_) => const SettingsPage(),
        CollectPage.route: (_) => const CollectPage(),
        HistoryPage.route: (_) => const HistoryPage(),
        SearchPage.route: (_) => const SearchPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AIacc.route) {
          final args = (settings.arguments ?? {}) as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AIacc(
              // 依你的 AIacc 頁面需求傳入
            ),
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
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
    const AiReportPage(),
    const AIacc(),
    const SearchPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    // 訂閱懸浮球事件
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event['action'] == 'open_page') {
        String page = event['page'];
        if (page == 'AIacc') {
          // 確保切換頁面時，主 UI 的狀態也會更新
          if (_currentIndex != 2) setState(() => _currentIndex = 2);
        } else if (page == 'SearchPage') {
          // 確保切換頁面時，主 UI 的狀態也會更新
          if (_currentIndex != 3) setState(() => _currentIndex = 3);
        }
      }
    });
  }

  void _onItemTapped(int index) => setState(() => _currentIndex = index);

  Future<void> _startGlobalFloatingBall() async {
    if (kIsWeb) return;

    // 1. 檢查並請求 SYSTEM_ALERT_WINDOW 權限
    bool granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      granted = await FlutterOverlayWindow.requestPermission() ?? false;
    }

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請授權懸浮窗權限才能啟動')),
        );
      }
      return;
    }

    // 2. 啟動懸浮服務
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "TruthLiesDetector",
      overlayContent: "AI懸浮球啟動中...",
      height: 120,
      width: 120,
      alignment: OverlayAlignment.centerRight,
      // 使用 OverlayFlag.defaultFlag 確保基本功能
      flag: OverlayFlag.defaultFlag, 
      visibility: NotificationVisibility.visibilityPrivate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 懸浮球已啟動")),
      );
    }
  }


  Future<void> _stopGlobalFloatingBall() async {
    if (kIsWeb) return;

    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🛑 懸浮球已關閉")),
        );
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
      body: Stack(
        children: [
          // 主要頁面
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // 底部導航列
          CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
          // App 內懸浮球 (如果需要，但通常 Global Overlay 會取代這個)
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
    );
  }
}

// =========================================================
// 自訂底部導航列 (放在 _MainLayoutState 外)
// =========================================================
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const mainGreen = AppColors.primaryGreen;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: mainGreen,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItem(Icons.home, "首頁", 0),
                _buildItem(Icons.analytics, "AI報告", 1),
                const SizedBox(width: 60), // 中間懸浮按鈕
                _buildItem(Icons.access_time, "查證", 3),
                _buildItem(Icons.person, "我的", 4),
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
                    // 確保 lib/assets/logo2.png 存在
                    child: Image.asset("lib/assets/logo2.png", height: 55, fit: BoxFit.contain), 
                  ),
                ),
              ),
            ),
          ],
        ),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}