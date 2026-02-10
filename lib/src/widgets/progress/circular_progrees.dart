import 'package:flutter/material.dart';
import 'dart:math';

class SpinningBigCircularProgress extends StatefulWidget {
  final double size;
  final String text;
  final bool isRunning;

  const SpinningBigCircularProgress({
    super.key,
    required this.text,
    this.size = 400,
    this.isRunning = false,
  });

  @override
  State<SpinningBigCircularProgress> createState() =>
      _SpinningBigCircularProgressState();
}

class _SpinningBigCircularProgressState
    extends State<SpinningBigCircularProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isControllerActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnimation(widget.isRunning);
    });
  }

  @override
  void didUpdateWidget(covariant SpinningBigCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRunning != widget.isRunning) {
      _updateAnimation(widget.isRunning);
    }
  }

  void _updateAnimation(bool run) {
    if (!mounted) return;
    if (run) {
      if (!_isControllerActive) {
        _controller.repeat();
        _isControllerActive = true;
      }
    } else {
      if (_isControllerActive) {
        _controller.stop();
        _isControllerActive = false;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CirclePainter(
                  progress: widget.isRunning ? 0.25 : 1.0,
                  rotation: widget.isRunning ? _controller.value * 2 * pi : 0,
                ),
              );
            },
          ),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.size * 0.08,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress; // 0.0 - 1.0
  final double rotation;

  _CirclePainter({required this.progress, this.rotation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.2)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // background full circle
    canvas.drawCircle(center, radius, bgPaint);

    // spinning/fill arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + rotation, // start rotated
      2 * pi * progress, // sweep angle
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.rotation != rotation;
}
