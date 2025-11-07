//cpr_training_app/lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileMaxWidth = 768;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1024;

  // Check device types
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileMaxWidth &&
        MediaQuery.of(context).size.width < desktopMinWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopMinWidth;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Get screen dimensions
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }

  // Get responsive dimensions
  static double getCardWidth(BuildContext context, {int columns = 1}) {
    double screenWidth = getScreenWidth(context);
    EdgeInsets padding = getScreenPadding(context);
    double availableWidth = screenWidth - (padding.left + padding.right);

    if (columns == 1) return availableWidth;

    double spacing = 8.0 * (columns - 1);
    return (availableWidth - spacing) / columns;
  }

  static double getAnimationSize(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 120 : 160;
    } else if (isTablet(context)) {
      return 200;
    } else {
      return 250;
    }
  }

  // Get responsive grid properties
  static int getMetricsGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 3 : 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  static double getMetricsCardAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 1.0 : 1.2;
    } else {
      return 1.2;
    }
  }

  // Get responsive font sizes
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 16.0 : 18.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 22.0;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 14.0 : 16.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 18.0;
    }
  }

  static double getCaptionFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else {
      return 14.0;
    }
  }

  // Get small font size
  static double getSmallFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 10.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 14.0;
    }
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context, {double base = 16.0}) {
    if (isMobile(context)) {
      return base * (isLandscape(context) ? 0.75 : 1.0);
    } else if (isTablet(context)) {
      return base;
    } else {
      return base * 1.25;
    }
  }

  static double getSmallSpacing(BuildContext context) {
    return getSpacing(context, base: 8.0);
  }

  static double getLargeSpacing(BuildContext context) {
    return getSpacing(context, base: 24.0);
  }

  // Get responsive button dimensions
  static Size getButtonSize(BuildContext context) {
    if (isMobile(context)) {
      return Size(120, isLandscape(context) ? 40 : 44);
    } else if (isTablet(context)) {
      return const Size(140, 48);
    } else {
      return const Size(160, 52);
    }
  }

  static EdgeInsets getButtonPadding(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape(context) ? 8 : 12,
      );
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  // Get responsive icon sizes
  static double getIconSize(BuildContext context, {double base = 24.0}) {
    if (isMobile(context)) {
      return base * (isLandscape(context) ? 0.9 : 1.0);
    } else if (isTablet(context)) {
      return base;
    } else {
      return base * 1.1;
    }
  }

  static double getSmallIconSize(BuildContext context) {
    return getIconSize(context, base: 16.0);
  }

  static double getLargeIconSize(BuildContext context) {
    return getIconSize(context, base: 32.0);
  }

  // Get responsive chart dimensions
  static double getChartHeight(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 200 : 300;
    } else if (isTablet(context)) {
      return 350;
    } else {
      return 400;
    }
  }

  // Layout helpers
  static bool shouldUseHorizontalLayout(BuildContext context) {
    return getScreenWidth(context) >= 640 && isLandscape(context);
  }

  static bool shouldUseCompactLayout(BuildContext context) {
    return isMobile(context) && isLandscape(context);
  }

  static bool shouldShowExtendedFAB(BuildContext context) {
    return !isMobile(context) || isLandscape(context);
  }

  // Safe area helpers
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  static double getAppBarHeight(BuildContext context) {
    return kToolbarHeight;
  }

  static double getBottomBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kBottomNavigationBarHeight;
    } else {
      return kBottomNavigationBarHeight + 8.0;
    }
  }

  // Alert panel height
  static double getAlertPanelHeight(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 70 : 80;
    } else if (isTablet(context)) {
      return 90;
    } else {
      return 100;
    }
  }

  // Animation panel height
  static double getAnimationPanelHeight(BuildContext context) {
    if (isMobile(context)) {
      return isLandscape(context) ? 200 : 250;
    } else if (isTablet(context)) {
      return 300;
    } else {
      return 350;
    }
  }
}
