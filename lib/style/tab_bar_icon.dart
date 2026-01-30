import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Base class for tab bar icons.
///
/// This is the parent type for both [CNSymbol] (SF Symbols) and [CNCustomIcon]
/// (Flutter IconData-based icons).
abstract class CNTabBarIcon {
  /// Creates a tab bar icon.
  const CNTabBarIcon();

  /// Whether this is an SF Symbol (native iOS/macOS symbol).
  bool get isSFSymbol;

  /// Whether this is a custom icon (Flutter IconData).
  bool get isCustomIcon => !isSFSymbol;
}

/// A custom icon created from Flutter's [IconData].
///
/// Use this to display icons from icon fonts like Material Icons,
/// Cupertino Icons, or custom icon packages in the native tab bar.
///
/// Example:
/// ```dart
/// CNTabBarItem(
///   label: 'Home',
///   icon: CNCustomIcon(Icons.home),
/// )
/// ```
class CNCustomIcon extends CNTabBarIcon {
  /// Creates a custom icon from Flutter [IconData].
  const CNCustomIcon(
    this.iconData, {
    this.size = 24.0,
    this.color,
  });

  /// The Flutter icon data (e.g., Icons.home, CupertinoIcons.house).
  final IconData iconData;

  /// Desired point size for the icon.
  final double size;

  /// Optional icon color. If null, uses the tab bar's tint color.
  final Color? color;

  @override
  bool get isSFSymbol => false;

  /// The Unicode code point of the icon.
  int get codePoint => iconData.codePoint;

  /// The font family of the icon.
  String? get fontFamily => iconData.fontFamily;

  /// The package containing the font (if any).
  String? get fontPackage => iconData.fontPackage;

  /// Renders this icon to PNG image bytes.
  ///
  /// This is used to pass the icon to native code since Flutter's icon fonts
  /// are not directly accessible from native iOS/macOS.
  ///
  /// The [targetSize] is the desired display size on native side (in points).
  /// The [scale] is used for retina rendering (2.0 or 3.0).
  Future<Uint8List?> renderToImageBytes({
    double targetSize = 22.0,
    double scale = 2.0,
    Color? overrideColor,
  }) async {
    // Render at scaled size for retina displays
    final renderSize = targetSize * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          fontSize: renderSize,
          color: overrideColor ?? color ?? const Color(0xFF000000),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      textPainter.width.ceil(),
      textPainter.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    return byteData?.buffer.asUint8List();
  }
}
