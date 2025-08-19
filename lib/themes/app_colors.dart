import 'package:flutter/material.dart';

// 定義一個 MaterialColor，以便 primary Color 可以使用十六進位顏色碼
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
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

// 定義您的自定義綠色 MaterialColor
final MaterialColor myCustomGreen = createMaterialColor(const Color(0xFF9EB79E));

// 您也可以在這裡定義其他常用的顏色常數
class AppColors {
  static const Color primaryGreen = Color(0xFF9EB79E);
  static const Color primaryGreen2 = Color(0xFF9FCC9F);
  static const Color accentGreen = Color(0xFFC8E6C9); // 如果您想保留之前用過的淺綠色
  static const Color textColor = Colors.black87;
  static const Color greyBackground = Colors.grey;
}