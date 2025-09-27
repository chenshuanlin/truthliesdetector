import 'package:flutter/material.dart';

// Helper function to create MaterialColor from a single Color
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

/// 應用程式中使用的所有顏色常數
class AppColors {
  // 主要色系
  static const Color primaryGreen = Color(0xFF7CB342); // 更亮、更有活力的綠色
  static const Color primaryGreen2 = Color(0xFF9CCC65); // 次要/強調綠色
  static const Color accentGreen = Color(0xFFC8E6C9); // 輔助/淡綠色

  // 警示色
  static const Color dangerRed = Color(0xFFE53935); 

  // 灰色和中性色
  static const Color userGray = Color(0xFF9E9E9E); // 用於次要文本或圖標
  static const Color backgroundLight = Color(0xFFF7F7F7); // 淺色背景
  static const Color greyBackground = Colors.grey; // 一般灰色背景

  // 綠色背景和標籤顏色
  static const Color lightGreenBG = Color(0xFFE8F5E9); // 輕微的綠色背景
  static const Color labelGreenBG = Color(0xFFC8E6C9); // 標籤專用綠色 (與 accentGreen 相同)
  
  // 深綠色調
  static const Color appBarGreen = Color(0xFF2E7D32); // AppBar 深綠色
  static const Color deepGreen = Color(0xFF1B5E20); // 最深綠色

  // 文本顏色
  static const Color darkText = Color(0xFF212121); // 主要深色文本
  static const Color textColor = Colors.black87; // 一般文本顏色

  // 漸層顏色（用於 SplashPage）
  static const Color gradientGreenStart = Color(0xFFE8F5E9);
  static const Color gradientGreenEnd = Color(0xFFDCEDC8);
}

/// 應用於 MaterialApp's primarySwatch 的 MaterialColor
final MaterialColor myCustomGreen = createMaterialColor(AppColors.primaryGreen);
