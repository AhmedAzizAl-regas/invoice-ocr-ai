import 'package:flutter/material.dart';

/// AppBranding defines the visual identity parameters of Invoice OCR AI.
/// It encapsulates the logo specifications, visual structures, and assets paths.
class AppBranding {
  AppBranding._();

  static const String appName = 'Invoice OCR AI';
  static const String appPackage = 'com.silkroadminingco.invoice_ocr_ai';

  // Assets Paths
  static const String logoPath = 'assets/brand/logo.png';
  static const String logoIconPath = 'assets/brand/logo_icon.png';
  static const String splashPath = 'assets/brand/splash_screen.png';

  // SVG or Path Draw Instructions for Custom Widgets (Drawing the brand logo via Canvas)
  // The logo design combines a receipt icon (Invoice), a scan frame (OCR), and neural connections (AI).
  static void drawLogoIcon(Canvas canvas, Size size, Color primaryColor, Color secondaryColor) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    // 1. Draw outer scanning borders
    paint.color = secondaryColor; // Red accent
    final margin = size.width * 0.1;
    final length = size.width * 0.2;

    // Top-Left corner
    canvas.drawLine(Offset(margin, margin + length), Offset(margin, margin), paint);
    canvas.drawLine(Offset(margin, margin), Offset(margin + length, margin), paint);

    // Top-Right corner
    canvas.drawLine(Offset(size.width - margin - length, margin), Offset(size.width - margin, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + length), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(margin, size.height - margin - length), Offset(margin, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + length, size.height - margin), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(size.width - margin - length, size.height - margin), Offset(size.width - margin, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - length), paint);

    // 2. Draw the Invoice (Receipt shape) inside
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final receiptWidth = size.width * 0.45;
    final receiptHeight = size.height * 0.55;
    final rx = (size.width - receiptWidth) / 2;
    final ry = (size.height - receiptHeight) / 2;

    final receiptRect = Rect.fromLTWH(rx, ry, receiptWidth, receiptHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(receiptRect, Radius.circular(size.width * 0.04)), fillPaint);

    // Invoice border
    paint.color = Colors.black;
    paint.strokeWidth = size.width * 0.04;
    canvas.drawRRect(RRect.fromRectAndRadius(receiptRect, Radius.circular(size.width * 0.04)), paint);

    // Invoice lines (representing items)
    paint.strokeWidth = size.width * 0.03;
    final lineYStart = ry + receiptHeight * 0.25;
    final lineSpacing = receiptHeight * 0.15;
    
    // Line 1
    canvas.drawLine(
      Offset(rx + receiptWidth * 0.2, lineYStart),
      Offset(rx + receiptWidth * 0.8, lineYStart),
      paint,
    );
    // Line 2
    canvas.drawLine(
      Offset(rx + receiptWidth * 0.2, lineYStart + lineSpacing),
      Offset(rx + receiptWidth * 0.6, lineYStart + lineSpacing),
      paint,
    );
    // Line 3 (Total line)
    paint.color = primaryColor; // Yellow highlight
    canvas.drawLine(
      Offset(rx + receiptWidth * 0.2, lineYStart + 2 * lineSpacing),
      Offset(rx + receiptWidth * 0.8, lineYStart + 2 * lineSpacing),
      paint,
    );

    // 3. Draw AI Neural Nodes & Connections (Glowing dots representing intelligence)
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = secondaryColor; // Red glowing node

    canvas.drawCircle(Offset(rx, ry + receiptHeight * 0.5), size.width * 0.05, nodePaint);
    canvas.drawCircle(Offset(rx + receiptWidth, ry + receiptHeight * 0.3), size.width * 0.05, nodePaint);
    canvas.drawCircle(Offset(size.width / 2, ry + receiptHeight), size.width * 0.05, nodePaint);

    // Connect node lines
    final connectionPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.6)
      ..strokeWidth = size.width * 0.02
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(rx, ry + receiptHeight * 0.5),
      Offset(rx + receiptWidth, ry + receiptHeight * 0.3),
      connectionPaint,
    );
    canvas.drawLine(
      Offset(rx + receiptWidth, ry + receiptHeight * 0.3),
      Offset(size.width / 2, ry + receiptHeight),
      connectionPaint,
    );
  }
}

/// LogoPainter is a custom painter that renders the Invoice OCR AI logo dynamically.
class LogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  LogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    AppBranding.drawLogoIcon(canvas, size, primaryColor, secondaryColor);
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor;
  }
}

/// BrandingLogoWidget is a Flutter widget rendering the logo dynamically in any size.
class BrandingLogoWidget extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const BrandingLogoWidget({
    super.key,
    required this.size,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = primaryColor ?? theme.primaryColor;
    final sColor = secondaryColor ?? theme.colorScheme.secondary;

    return CustomPaint(
      size: Size(size, size),
      painter: LogoPainter(primaryColor: pColor, secondaryColor: sColor),
    );
  }
}
