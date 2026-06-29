import 'package:flutter/material.dart';

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, -0.08, 1.22, false, paint..color = _blue);
    canvas.drawArc(arcRect, 1.20, 1.52, false, paint..color = _green);
    canvas.drawArc(arcRect, 2.70, 1.00, false, paint..color = _yellow);
    canvas.drawArc(arcRect, 3.64, 1.40, false, paint..color = _red);

    final midY = size.height * 0.52;
    final startX = size.width * 0.52;
    final endX = size.width * 0.88;
    canvas.drawLine(
      Offset(startX, midY),
      Offset(endX, midY),
      paint
        ..color = _blue
        ..strokeCap = StrokeCap.square,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
