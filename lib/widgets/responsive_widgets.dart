//cpr_training_app/lib/widgets/responsive_widgets.dart
// import 'package:flutter/material.dart';
// import '../utils/responsive_utils.dart';
//
// class ResponsiveCard extends StatelessWidget {
//   final Widget child;
//   final EdgeInsets? padding;
//   final double? elevation;
//   final Color? color;
//   final double? height;
//   final double? width;
//
//   const ResponsiveCard({
//     super.key,
//     required this.child,
//     this.padding,
//     this.elevation,
//     this.color,
//     this.height,
//     this.width,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: elevation ?? 2,
//       color: color,
//       child: Container(
//         height: height,
//         width: width,
//         padding: padding ?? ResponsiveUtils.getCardPadding(context),
//         child: child,
//       ),
//     );
//   }
// }
//
// class ResponsiveButton extends StatelessWidget {
//   final String text;
//   final VoidCallback? onPressed;
//   final IconData? icon;
//   final Color? backgroundColor;
//   final Color? textColor;
//   final bool isExpanded;
//   final bool isEnabled;
//
//   const ResponsiveButton({
//     super.key,
//     required this.text,
//     this.onPressed,
//     this.icon,
//     this.backgroundColor,
//     this.textColor,
//     this.isExpanded = false,
//     this.isEnabled = true,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final buttonPadding = ResponsiveUtils.getButtonPadding(context);
//     final fontSize = ResponsiveUtils.getBodyFontSize(context);
//     final iconSize = ResponsiveUtils.getIconSize(context, base: 20);
//
//     Widget buttonChild = Row(
//       mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: iconSize, color: textColor),
//           SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
//         ],
//         Flexible(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: fontSize,
//               fontWeight: FontWeight.w600,
//               color: textColor,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//
//     if (isExpanded) {
//       return SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: isEnabled ? onPressed : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: backgroundColor,
//               foregroundColor: textColor,
//               padding: buttonPadding,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: buttonChild,
//           ));
//     }
//
//     return ElevatedButton(
//       onPressed: isEnabled ? onPressed : null,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: backgroundColor,
//         foregroundColor: textColor,
//         padding: buttonPadding,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       child: buttonChild,
//     );
//   }
// }
//
// class ResponsiveText extends StatelessWidget {
//   final String text;
//   final TextStyle? style;
//   final TextAlign? textAlign;
//   final int? maxLines;
//   final TextOverflow? overflow;
//   final bool isTitle;
//   final bool isCaption;
//
//   const ResponsiveText({
//     super.key,
//     required this.text,
//     this.style,
//     this.textAlign,
//     this.maxLines,
//     this.overflow,
//     this.isTitle = false,
//     this.isCaption = false,
//   });
//
//   factory ResponsiveText.title(
//     String text, {
//     Key? key,
//     TextStyle? style,
//     TextAlign? textAlign,
//     int? maxLines,
//     TextOverflow? overflow,
//   }) {
//     return ResponsiveText(
//       key: key,
//       text: text,
//       style: style,
//       textAlign: textAlign,
//       maxLines: maxLines,
//       overflow: overflow,
//       isTitle: true,
//     );
//   }
//
//   factory ResponsiveText.body(
//     String text, {
//     Key? key,
//     TextStyle? style,
//     TextAlign? textAlign,
//     int? maxLines,
//     TextOverflow? overflow,
//   }) {
//     return ResponsiveText(
//       key: key,
//       text: text,
//       style: style,
//       textAlign: textAlign,
//       maxLines: maxLines,
//       overflow: overflow,
//     );
//   }
//
//   factory ResponsiveText.caption(
//     String text, {
//     Key? key,
//     TextStyle? style,
//     TextAlign? textAlign,
//     int? maxLines,
//     TextOverflow? overflow,
//   }) {
//     return ResponsiveText(
//       key: key,
//       text: text,
//       style: style,
//       textAlign: textAlign,
//       maxLines: maxLines,
//       overflow: overflow,
//       isCaption: true,
//     );
//   }
//
//   factory ResponsiveText.small(
//     String text, {
//     Key? key,
//     TextStyle? style,
//     TextAlign? textAlign,
//     int? maxLines,
//     TextOverflow? overflow,
//   }) {
//     return ResponsiveText(
//       key: key,
//       text: text,
//       style: style,
//       textAlign: textAlign,
//       maxLines: maxLines,
//       overflow: overflow,
//       isCaption: true,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double fontSize;
//     FontWeight fontWeight;
//
//     if (isTitle) {
//       fontSize = ResponsiveUtils.getTitleFontSize(context);
//       fontWeight = FontWeight.bold;
//     } else if (isCaption) {
//       fontSize = ResponsiveUtils.getCaptionFontSize(context);
//       fontWeight = FontWeight.normal;
//     } else {
//       fontSize = ResponsiveUtils.getBodyFontSize(context);
//       fontWeight = FontWeight.normal;
//     }
//
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: fontSize,
//         fontWeight: fontWeight,
//       ).merge(style),
//       textAlign: textAlign,
//       maxLines: maxLines,
//       overflow: overflow,
//     );
//   }
// }
//
// class ResponsiveMetricCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color color;
//   final bool isCompact;
//
//   const ResponsiveMetricCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.icon,
//     required this.color,
//     this.isCompact = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final cardPadding = isCompact
//         ? EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context))
//         : ResponsiveUtils.getCardPadding(context);
//
//     final iconSize = isCompact
//         ? ResponsiveUtils.getSmallIconSize(context)
//         : ResponsiveUtils.getIconSize(context);
//
//     final titleFontSize = isCompact
//         ? ResponsiveUtils.getCaptionFontSize(context)
//         : ResponsiveUtils.getBodyFontSize(context);
//
//     final valueFontSize = isCompact
//         ? ResponsiveUtils.getBodyFontSize(context)
//         : ResponsiveUtils.getTitleFontSize(context);
//
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: cardPadding,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: color,
//               size: iconSize,
//             ),
//             SizedBox(height: ResponsiveUtils.getSmallSpacing(context)),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: titleFontSize,
//                 color: Colors.grey.shade600,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             SizedBox(height: ResponsiveUtils.getSmallSpacing(context) / 2),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: valueFontSize,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ResponsiveAnimationPanel extends StatelessWidget {
//   final Widget child;
//   final String title;
//   final double? size;
//
//   const ResponsiveAnimationPanel({
//     super.key,
//     required this.child,
//     required this.title,
//     this.size,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final animationSize = size ?? ResponsiveUtils.getAnimationSize(context);
//     final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
//     final spacing = ResponsiveUtils.getSpacing(context);
//
//     return ResponsiveCard(
//       child: SizedBox(
//         height: ResponsiveUtils.getAnimationPanelHeight(context),
//         child: Column(
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: titleFontSize,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: spacing),
//             Expanded(
//               child: Center(
//                 child: SizedBox(
//                   width: animationSize,
//                   height: animationSize,
//                   child: child,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ResponsiveAlertPanel extends StatelessWidget {
//   final String? alertMessage;
//   final String? alertType;
//   final bool isActive;
//   final double? maxHeight;
//
//   const ResponsiveAlertPanel({
//     super.key,
//     this.alertMessage,
//     this.alertType,
//     this.isActive = false,
//     this.maxHeight,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
//     final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
//     final captionFontSize = ResponsiveUtils.getCaptionFontSize(context);
//     final spacing = ResponsiveUtils.getSpacing(context);
//
//     return ResponsiveCard(
//       child: Container(
//         height: maxHeight ?? ResponsiveUtils.getAlertPanelHeight(context),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.warning,
//                   color: Colors.orange,
//                   size: ResponsiveUtils.getIconSize(context),
//                 ),
//                 SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
//                 Text(
//                   'Alerts',
//                   style: TextStyle(
//                     fontSize: titleFontSize,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 if (isActive)
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       'ACTIVE',
//                       style: TextStyle(
//                         fontSize: captionFontSize,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.red,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             SizedBox(height: spacing),
//             Expanded(
//               child: alertMessage != null
//                   ? Container(
//                       width: double.infinity,
//                       padding: EdgeInsets.all(spacing),
//                       decoration: BoxDecoration(
//                         color: _getAlertColor(alertType),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             alertMessage!,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: bodyFontSize,
//                             ),
//                           ),
//                           if (alertType != null) ...[
//                             SizedBox(
//                                 height:
//                                     ResponsiveUtils.getSmallSpacing(context) /
//                                         2),
//                             Text(
//                               'Alert Type: ${alertType!}',
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: captionFontSize,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     )
//                   : Center(
//                       child: Text(
//                         'No active alerts',
//                         style: TextStyle(
//                           color: Colors.grey,
//                           fontSize: bodyFontSize,
//                         ),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Color _getAlertColor(String? type) {
//     switch (type?.toLowerCase()) {
//       case 'too_slow':
//       case 'slow':
//         return Colors.blue.shade600;
//       case 'too_fast':
//       case 'fast':
//         return Colors.red.shade600;
//       case 'too_deep':
//       case 'deep':
//         return Colors.orange.shade600;
//       case 'insufficient_recoil':
//       case 'recoil':
//         return Colors.purple.shade600;
//       default:
//         return Colors.grey.shade600;
//     }
//   }
// }
//
// class ResponsiveLayout extends StatelessWidget {
//   final Widget mobile;
//   final Widget? tablet;
//   final Widget? desktop;
//
//   const ResponsiveLayout({
//     super.key,
//     required this.mobile,
//     this.tablet,
//     this.desktop,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (ResponsiveUtils.isDesktop(context) && desktop != null) {
//       return desktop!;
//     } else if (ResponsiveUtils.isTablet(context) && tablet != null) {
//       return tablet!;
//     } else {
//       return mobile;
//     }
//   }
// }
//
// class ResponsiveGrid extends StatelessWidget {
//   final List<Widget> children;
//   final int? crossAxisCount;
//   final double? childAspectRatio;
//   final double? mainAxisSpacing;
//   final double? crossAxisSpacing;
//
//   const ResponsiveGrid({
//     super.key,
//     required this.children,
//     this.crossAxisCount,
//     this.childAspectRatio,
//     this.mainAxisSpacing,
//     this.crossAxisSpacing,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final responsiveCrossAxisCount =
//         crossAxisCount ?? ResponsiveUtils.getMetricsGridCrossAxisCount(context);
//     final responsiveAspectRatio =
//         childAspectRatio ?? ResponsiveUtils.getMetricsCardAspectRatio(context);
//     final spacing = ResponsiveUtils.getSmallSpacing(context);
//
//     return GridView.builder(
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: responsiveCrossAxisCount,
//         childAspectRatio: responsiveAspectRatio,
//         crossAxisSpacing: crossAxisSpacing ?? spacing,
//         mainAxisSpacing: mainAxisSpacing ?? spacing,
//       ),
//       itemCount: children.length,
//       itemBuilder: (context, index) => children[index],
//     );
//   }
// }
//
// class ResponsiveScrollView extends StatelessWidget {
//   final List<Widget> children;
//   final EdgeInsets? padding;
//   final ScrollPhysics? physics;
//
//   const ResponsiveScrollView({
//     super.key,
//     required this.children,
//     this.padding,
//     this.physics,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: padding ?? ResponsiveUtils.getScreenPadding(context),
//       physics: physics,
//       child: Column(
//         children: children,
//       ),
//     );
//   }
// }
//
// class ResponsiveIconButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onPressed;
//   final String? tooltip;
//   final Color? color;
//   final double? size;
//
//   const ResponsiveIconButton({
//     super.key,
//     required this.icon,
//     required this.onPressed,
//     this.tooltip,
//     this.color,
//     this.size,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final iconSize = size ?? ResponsiveUtils.getIconSize(context);
//
//     return IconButton(
//       icon: Icon(icon, size: iconSize),
//       color: color,
//       onPressed: onPressed,
//       tooltip: tooltip,
//     );
//   }
// }


//cpr_training_app/lib/widgets/responsive_widgets.dart
import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final double? height;
  final double? width;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      color: color,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? ResponsiveUtils.getCardPadding(context),
        child: child,
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isExpanded;
  final bool isEnabled;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isExpanded = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonPadding = ResponsiveUtils.getButtonPadding(context);
    final fontSize = ResponsiveUtils.getBodyFontSize(context);
    final iconSize = ResponsiveUtils.getIconSize(context, base: 20);

    Widget buttonChild = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: textColor),
          SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isExpanded) {
      return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: buttonChild,
          ));
    }

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: buttonChild,
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isTitle;
  final bool isCaption;

  const ResponsiveText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTitle = false,
    this.isCaption = false,
  });

  factory ResponsiveText.title(
      String text, {
        Key? key,
        TextStyle? style,
        TextAlign? textAlign,
        int? maxLines,
        TextOverflow? overflow,
      }) {
    return ResponsiveText(
      key: key,
      text: text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      isTitle: true,
    );
  }

  factory ResponsiveText.body(
      String text, {
        Key? key,
        TextStyle? style,
        TextAlign? textAlign,
        int? maxLines,
        TextOverflow? overflow,
      }) {
    return ResponsiveText(
      key: key,
      text: text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory ResponsiveText.caption(
      String text, {
        Key? key,
        TextStyle? style,
        TextAlign? textAlign,
        int? maxLines,
        TextOverflow? overflow,
      }) {
    return ResponsiveText(
      key: key,
      text: text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      isCaption: true,
    );
  }

  factory ResponsiveText.small(
      String text, {
        Key? key,
        TextStyle? style,
        TextAlign? textAlign,
        int? maxLines,
        TextOverflow? overflow,
      }) {
    return ResponsiveText(
      key: key,
      text: text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      isCaption: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontSize;
    FontWeight fontWeight;

    if (isTitle) {
      fontSize = ResponsiveUtils.getTitleFontSize(context);
      fontWeight = FontWeight.bold;
    } else if (isCaption) {
      fontSize = ResponsiveUtils.getCaptionFontSize(context);
      fontWeight = FontWeight.normal;
    } else {
      fontSize = ResponsiveUtils.getBodyFontSize(context);
      fontWeight = FontWeight.normal;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: Colors.white, // White text for dark mode
      ).merge(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class ResponsiveMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isCompact;

  const ResponsiveMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = isCompact
        ? EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context))
        : ResponsiveUtils.getCardPadding(context);

    final iconSize = isCompact
        ? ResponsiveUtils.getSmallIconSize(context)
        : ResponsiveUtils.getIconSize(context);

    final titleFontSize = isCompact
        ? ResponsiveUtils.getCaptionFontSize(context)
        : ResponsiveUtils.getBodyFontSize(context);

    final valueFontSize = isCompact
        ? ResponsiveUtils.getBodyFontSize(context)
        : ResponsiveUtils.getTitleFontSize(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: iconSize,
            ),
            SizedBox(height: ResponsiveUtils.getSmallSpacing(context)),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                color: Colors.grey.shade400, // Lighter grey for dark mode
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveUtils.getSmallSpacing(context) / 2),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for dark mode
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveAnimationPanel extends StatelessWidget {
  final Widget child;
  final String title;
  final double? size;

  const ResponsiveAnimationPanel({
    super.key,
    required this.child,
    required this.title,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final animationSize = size ?? ResponsiveUtils.getAnimationSize(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final spacing = ResponsiveUtils.getSpacing(context);

    return ResponsiveCard(
      child: SizedBox(
        height: ResponsiveUtils.getAnimationPanelHeight(context),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for dark mode
              ),
            ),
            SizedBox(height: spacing),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: animationSize,
                  height: animationSize,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveAlertPanel extends StatelessWidget {
  final String? alertMessage;
  final String? alertType;
  final bool isActive;
  final double? maxHeight;

  const ResponsiveAlertPanel({
    super.key,
    this.alertMessage,
    this.alertType,
    this.isActive = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final captionFontSize = ResponsiveUtils.getCaptionFontSize(context);
    final spacing = ResponsiveUtils.getSpacing(context);

    return ResponsiveCard(
      child: Container(
        height: maxHeight ?? ResponsiveUtils.getAlertPanelHeight(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
                Text(
                  'Alerts',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for dark mode
                  ),
                ),
                Spacer(),
                if (isActive)
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade800, // Darker red for dark mode
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: captionFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacing),
            Expanded(
              child: alertMessage != null
                  ? Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing),
                decoration: BoxDecoration(
                  color: _getAlertColor(alertType),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alertMessage!,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    if (alertType != null) ...[
                      SizedBox(
                          height:
                          ResponsiveUtils.getSmallSpacing(context) /
                              2),
                      Text(
                        'Alert Type: ${alertType!}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: captionFontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  : Center(
                child: Text(
                  'No active alerts',
                  style: TextStyle(
                    color: Colors.grey.shade400, // Lighter grey for dark mode
                    fontSize: bodyFontSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAlertColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'too_slow':
      case 'slow':
        return Colors.blue.shade800; // Darker blue for dark mode
      case 'too_fast':
      case 'fast':
        return Colors.red.shade800; // Darker red for dark mode
      case 'too_deep':
      case 'deep':
        return Colors.orange.shade800; // Darker orange for dark mode
      case 'insufficient_recoil':
      case 'recoil':
        return Colors.purple.shade800; // Darker purple for dark mode
      default:
        return Colors.grey.shade800; // Darker grey for dark mode
    }
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveCrossAxisCount =
        crossAxisCount ?? ResponsiveUtils.getMetricsGridCrossAxisCount(context);
    final responsiveAspectRatio =
        childAspectRatio ?? ResponsiveUtils.getMetricsCardAspectRatio(context);
    final spacing = ResponsiveUtils.getSmallSpacing(context);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount,
        childAspectRatio: responsiveAspectRatio,
        crossAxisSpacing: crossAxisSpacing ?? spacing,
        mainAxisSpacing: mainAxisSpacing ?? spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveScrollView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const ResponsiveScrollView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? ResponsiveUtils.getScreenPadding(context),
      physics: physics,
      child: Column(
        children: children,
      ),
    );
  }
}

class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;
  final double? size;

  const ResponsiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? ResponsiveUtils.getIconSize(context);

    return IconButton(
      icon: Icon(icon, size: iconSize),
      color: color ?? Colors.white, // White icons for dark mode
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}