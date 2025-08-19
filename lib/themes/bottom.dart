
import 'package:flutter/material.dart';
import 'package:truthliesdetector/themes/app_colors.dart'; // 導入自定義顏色

/// 一個可自訂的底部導航欄 Widget，現在使用 BottomAppBar 實現凹槽效果。
/// 它接收當前選中的索引和點擊事件回調。
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), // 中間凹槽形狀，用於浮動動作按鈕
      notchMargin: 8.0, // 凹槽與浮動動作按鈕之間的間距
      color: AppColors.primaryGreen, // 導航欄背景色
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // 平均分佈項目
        children: <Widget>[
          // 首頁項目 (索引 0)
          IconButton(
            icon: Icon(
              Icons.home, // 使用 home 圖示
              color: currentIndex == 0 ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            onPressed: () => onTap(0),
          ),
          // 發現項目 (索引 1)
          IconButton(
            icon: Icon(
              Icons.explore, // 使用 explore 圖示
              color: currentIndex == 1 ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            onPressed: () => onTap(1),
          ),
          // 用於容納浮動動作按鈕的間距
          const SizedBox(width: 60.0), // 預留空間比 FAB 略寬，確保導航項目正確對齊
          // 搜尋項目 (索引 2)
          IconButton(
            icon: Icon(
              Icons.search, // 使用 search 圖示
              color: currentIndex == 2 ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            onPressed: () => onTap(2),
          ),
          // 我的項目 (索引 3)
          IconButton(
            icon: Icon(
              Icons.person, // 使用 person 圖示
              color: currentIndex == 3 ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            onPressed: () => onTap(3),
          ),
        ],
      ),
    );
  }
}
