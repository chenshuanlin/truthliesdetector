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

// 自訂主題綠
final MaterialColor myCustomGreen =
    createMaterialColor(const Color(0xFF9EB79E));

class AppColors {
  static const Color primaryGreen = Color(0xFF9EB79E);
  static const Color primaryGreen2 = Color(0xFF9FCC9F);
  static const Color accentGreen = Color(0xFFC8E6C9);

  // 原有
  static const Color textColor = Colors.black87;
  static const Color greyBackground = Colors.grey;

  // 新增補齊（給 Article_page 用）
  static const Color appBarGreen = Color(0xFF2E7D32);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color lightGreenBG = Color(0xFFE8F5E9);
  static const Color deepGreen = Color(0xFF1B5E20);
  static const Color darkText = Color(0xFF212121);
  static const Color labelGreenBG = Color(0xFFC8E6C9);
  static const Color userGray = Color(0xFF9E9E9E);

  // 舊顏色（現在已不需要，因為已被更新或取代）
  // static const Color primaryGreen = Color(0xFF678983);
  // static const Color sage = Color(0xFF9EB79E);
  // static const Color sageDeep = Color(0xFF8EAA98);
}
