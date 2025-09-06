import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/AIacc.dart'; // 導入 AI 辨識介面
import 'package:truthliesdetector/themes/app_colors.dart'; // 導入自定義顏色
import 'package:truthliesdetector/themes/app_colors.dart' as app_colors_file; // 導入整個檔案以使用 myCustomGreen
import 'package:truthliesdetector/screens/ball.dart'; // 導入懸浮球功能
import 'package:screenshot/screenshot.dart'; // 導入截圖插件
import 'package:truthliesdetector/themes/bottom.dart'; // 導入底部導航欄文件

// 應用程式的主要進入點
import 'package:truthliesdetector/screens/search_page.dart';
import 'package:truthliesdetector/screens/settings_page.dart';
import 'package:truthliesdetector/screens/history_page.dart';
import 'package:truthliesdetector/screens/collect_page.dart';

void main() {
  runApp(const MyApp());
}

// MyApp 是應用程式的根 Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }

  // 底部導航欄項目點擊事件處理函數
  void _onBottomBarItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 凸起的 AI 按鈕點擊事件處理函數
  void _onAiButtonTapped() {
    setState(() {
      _currentIndex = 2; // 直接切換到 AI 助手頁面
    });
  }

  // 懸浮球的開關功能
  void _toggleFloatingButton() {
    setState(() {
      _showFloatingButton = !_showFloatingButton;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // 使用 Stack 允許多個 Widget 疊加，包括可拖曳的 FloatingActionMenu 懸浮球
        children: [
          // 顯示當前選中的底部導航欄頁面內容
          _bottomBarPages[_currentIndex],
          // 根據 _showFloatingButton 狀態決定是否顯示懸浮球
          if (_showFloatingButton)
            FloatingActionMenu(
              screenshotController: screenshotController,
              onTap: (index) {
                // 懸浮球子按鈕點擊後，切換到對應的頁面
                _onBottomBarItemTapped(index);
              },
              onClose: () {
                // 懸浮球的關閉回呼，調用 _toggleFloatingButton 隱藏懸浮球
                _toggleFloatingButton();
              },
            ),
        ],
      ),
      // 中間凸起的「真假聊聊」浮動動作按鈕
      floatingActionButton: FloatingActionButton(
        heroTag: 'protrudingAiButton', // 確保唯一的 heroTag，避免動畫衝突
        backgroundColor: AppColors.primaryGreen, // 按鈕背景色為綠色
        shape: const CircleBorder( // 圓形按鈕，帶有白色邊框
          side: BorderSide(color: Colors.white, width: 3), // 白色邊框
        ),
        onPressed: _onAiButtonTapped, // 使用專門的點擊處理函數
        child: Container(
          padding: const EdgeInsets.all(5), // 內部填充
          child: Image.asset( // 使用 Image.asset 加載 logo2.png 圖片
            'lib/assets/logo2.png', // 使用正確的 logo2.png 路徑
            width: 150, // 調整 Logo 寬度
            height: 100, // 調整 Logo 高度
          ),
        ),
      ),
      // 將浮動動作按鈕定位在底部應用欄的中間凹槽
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // 使用自定義的 BottomNavBar Widget 作為底部應用欄
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex, // 將當前索引傳遞給導航欄
        onTap: _onBottomBarItemTapped, // 傳遞點擊事件處理函數
      ),
    );
  }
}