import 'package:flutter/material.dart';

/// Bảng màu trích từ bản Android PTalk-Signature (res/values/colors.xml).
class AppColors {
  // Gradient nền (xanh lá nhạt)
  static const gradTop = Color(0xFFE8F5E9);
  static const gradMid = Color(0xFFC8E6C9);
  static const gradBottom = Color(0xFFB2DFDB);

  // Text
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF707072);
  static const textMuted = Color(0xFF9E9EA0);
  static const textBody = Color(0xFF4A4A4A);

  // Đường kẻ / divider
  static const dividerLine = Color(0xFFE5E5E5);
  static const dividerSubtle = Color(0xFFECECEC);

  // Liên kết / lỗi
  static const linkBlue = Color(0xFF0066CC);
  static const error = Color(0xFFD30005);

  // Nút đăng nhập (pill đen)
  static const buttonDark = Color(0xFF111111);

  // Chủ đề Kid (xanh)
  static const accentKid = Color(0xFF4CAF50);
  static const accentKidDark = Color(0xFF2E7D52);
  static const kidCardBg = Color(0xFFEFF8F1);
  static const kidBadgeBg = Color(0xFFE3F4E8);
  static const kidHalo = Color(0xFFE6F5EB);

  // Chủ đề Elder (cam)
  static const accentElder = Color(0xFFE67E22);
  static const accentElderDark = Color(0xFFD35400);
  static const elderCardBg = Color(0xFFFCF1E8);
  static const elderBadgeBg = Color(0xFFFBE7D5);
  static const elderHalo = Color(0xFFFCEBDB);
  static const elderGradTop = Color(0xFFF0D8C8);
  static const elderGradMid = Color(0xFFF5E8E0);
  static const elderGradBottom = Color(0xFFFFF3E8);

  // Greeting / status theo mode
  static const greetingKid = Color(0xFF6BAF8A);
  static const greetingElder = Color(0xFFD35400);
  static const subGreetingElder = Color(0xFFBF6516);
  static const statusKid = Color(0xFF8BAF9A);

  // Dark mode (nền tối)
  static const darkGradTop = Color(0xFF0E1A14);
  static const darkGradMid = Color(0xFF13241C);
  static const darkGradBottom = Color(0xFF0B1712);
  static const darkText = Color(0xFFECEFF1);

  /// Gradient nền chung cho Splash/Login/ModeSelect (Kid, sáng).
  static const screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradTop, gradMid, gradBottom],
  );

  static const elderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [elderGradTop, elderGradMid, elderGradBottom],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkGradTop, darkGradMid, darkGradBottom],
  );

  /// Gradient phù hợp theo chế độ Elder & dark mode.
  static LinearGradient screenGradientFor(
      {required bool elder, required bool dark}) {
    if (dark) return darkGradient;
    return elder ? elderGradient : screenGradient;
  }

  /// Màu chữ chính theo nền sáng/tối.
  static Color textOn(bool dark) => dark ? darkText : textPrimary;
}
