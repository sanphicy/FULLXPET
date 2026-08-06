import 'package:flutter_screenutil/flutter_screenutil.dart';

// 全局尺寸常量
class Dimens {
  // 页面与屏幕边距
  static double get pagePadding => 30.w;
  static double get screenPadding => 16.w;

  // 元素间距
  static double get spacingMini => 4.h;
  static double get spacingSmall => 8.h;
  static double get spacingNormal => 16.h;
  static double get spacingLarge => 24.h;
  static double get spacingXLarge => 32.h;

  // 按钮高度
  static double get buttonLarge => 50.h;
  static double get buttonNormal => 40.h;
  static double get buttonSmall => 32.h;
  static double get buttonMini => 24.h;

  // 圆角大小
  static double get radiusSmall => 8.r;
  static double get radiusNormal => 12.r;
  static double get radiusLarge => 16.r;
  static double get radiusXLarge => 24.r;
  static double get radiusMax => 999.r;

  // 图标尺寸
  static double get iconSmall => 16.w;
  static double get iconNormal => 24.w;
  static double get iconLarge => 32.w;
  static double get iconHuge => 80.w;

  // 字体大小
  static double get fontMini => 10.sp;
  static double get fontSmall => 12.sp;
  static double get fontNormal => 14.sp;
  static double get fontMedium => 16.sp;
  static double get fontLarge => 18.sp;
  static double get fontHuge => 24.sp;
  static double get fontLogo => 28.sp;

  // 边框宽度
  static double get borderThin => 1.w;
  static double get borderNormal => 2.w;
  static double get borderThick => 3.w;

  // 字间距
  static double get letterSpacingNormal => 2.w;
  static double get letterSpacingLarge => 4.w;

  // 阴影参数
  static double get shadowRadius => 10.r;
  static double get shadowOffset => 5.h;
}
