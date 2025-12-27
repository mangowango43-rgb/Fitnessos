import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CyberGridBackground extends StatefulWidget {
  final Widget child;
  
  const CyberGridBackground({
    super.key,
    required this.child,
  });

  @override
  State<CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<CyberGridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Black background
        Container(color: Colors.black),
        
        // Animated grid
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: CyberGridPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        
        // Particles
        ...List.generate(15, (i) => _Particle(index: i)),
        
        // Content
        widget.child,
      ],
    );
  }
}

class CyberGridPainter extends CustomPainter {
  final double animation;
  
  CyberGridPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricCyan.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 50.0;
    final offsetX = (animation * gridSize) % gridSize;
    final offsetY = (animation * gridSize) % gridSize;

    // Draw vertical lines
    for (double x = -gridSize; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x + offsetX, 0),
        Offset(x + offsetX, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = -gridSize; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y + offsetY),
        Offset(size.width, y + offsetY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CyberGridPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _Particle extends StatefulWidget {
  final int index;

  const _Particle({required this.index});

  @override
  State<_Particle> createState() => _ParticleState();
}

class _ParticleState extends State<_Particle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _leftPosition;

  @override
  void initState() {
    super.initState();
    _leftPosition = (widget.index * 7 % 100).toDouble();
    _controller = AnimationController(
      duration: Duration(seconds: 8 + (widget.index % 4)),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: -0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _leftPosition / 100,
          top: MediaQuery.of(context).size.height * _animation.value,
          child: Container(
            width: 2,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.electricCyan.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

