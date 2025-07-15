/**
 * JitsuFlow カラフルテーマ
 * 鮮やかでエネルギッシュなデザインテーマ
 */

import 'package:flutter/material.dart';

class ColorfulTheme {
  // プライマリーグラデーション（紫→青→緑）
  static const List<Color> primaryGradient = [
    Color(0xFF6A1B9A), // ディープパープル
    Color(0xFF1976D2), // ブルー
    Color(0xFF388E3C), // グリーン
  ];

  // セカンダリーグラデーション（オレンジ→ピンク）
  static const List<Color> secondaryGradient = [
    Color(0xFFFF6F00), // オレンジ
    Color(0xFFE91E63), // ピンク
  ];

  // アクセントカラー
  static const Color accentLime = Color(0xFF8BC34A);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentAmber = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);

  // カード用グラデーション
  static const List<Color> cardGradient1 = [
    Color(0xFFE1F5FE),
    Color(0xFFE8F5E8),
  ];

  static const List<Color> cardGradient2 = [
    Color(0xFFFCE4EC),
    Color(0xFFF3E5F5),
  ];

  static const List<Color> cardGradient3 = [
    Color(0xFFFFF3E0),
    Color(0xFFF1F8E9),
  ];

  // メインテーマ
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansJP',
      
      // カラースキーム
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGradient[1],
        brightness: Brightness.light,
        primary: primaryGradient[1],
        secondary: secondaryGradient[0],
        tertiary: accentLime,
        surface: Colors.white,
        background: const Color(0xFFF8F9FA),
      ),

      // AppBar テーマ
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // カードテーマ
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),

      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // チップテーマ
      chipTheme: ChipThemeData(
        backgroundColor: accentLime.withOpacity(0.2),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),

      // 入力フィールドテーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGradient[1].withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGradient[1],
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ボトムナビゲーションテーマ
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: Color(0xFF6A1B9A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // グラデーション背景ウィジェット
  static Widget gradientBackground({
    required Widget child,
    List<Color>? colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? primaryGradient,
        ),
      ),
      child: child,
    );
  }

  // カラフルカードウィジェット
  static Widget colorfulCard({
    required Widget child,
    int colorVariant = 1,
    double elevation = 8,
    EdgeInsets margin = const EdgeInsets.all(8),
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    List<Color> gradientColors;
    switch (colorVariant % 3) {
      case 0:
        gradientColors = cardGradient1;
        break;
      case 1:
        gradientColors = cardGradient2;
        break;
      default:
        gradientColors = cardGradient3;
        break;
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }

  // グラデーションボタン
  static Widget gradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    List<Color>? colors,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    double borderRadius = 25,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? secondaryGradient,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (colors ?? secondaryGradient)[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  // アイコンカラーを取得
  static Color getIconColor(int index) {
    final colors = [
      accentLime,
      accentCyan,
      accentAmber,
      accentPurple,
      primaryGradient[0],
      primaryGradient[2],
    ];
    return colors[index % colors.length];
  }

  // プログレスインジケーターカラー
  static Widget colorfulProgressIndicator({double? value}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: primaryGradient),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.transparent,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  // チップ色バリエーション
  static List<Color> chipColors = [
    accentLime,
    accentCyan,
    accentAmber,
    accentPurple,
    secondaryGradient[0],
    secondaryGradient[1],
  ];

  static Color getChipColor(int index) {
    return chipColors[index % chipColors.length];
  }
}