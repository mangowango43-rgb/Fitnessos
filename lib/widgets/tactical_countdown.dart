import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// TACTICAL COUNTDOWN WIDGET
/// 5-second countdown that only activates when body is in frame
class TacticalCountdown extends StatefulWidget {
  final bool bodyDetected;
  final VoidCallback onComplete;

  const TacticalCountdown({
    super.key,
    required this.bodyDetected,
    required this.onComplete,
  });

  @override
  State<TacticalCountdown> createState() => _TacticalCountdownState();
}

class _TacticalCountdownState extends State<TacticalCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _countdown = 5;
  bool _countdownStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(TacticalCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start countdown only when body detected
    if (widget.bodyDetected && !_countdownStarted) {
      _startCountdown();
    }

    // Reset if body lost
    if (!widget.bodyDetected && _countdownStarted) {
      _resetCountdown();
    }
  }

  void _startCountdown() {
    setState(() => _countdownStarted = true);
    _tick();
  }

  void _tick() {
    if (_countdown > 0) {
      _controller
        ..reset()
        ..forward().then((_) {
          if (mounted) {
            setState(() => _countdown--);
            if (_countdown > 0) {
              _tick();
            } else {
              widget.onComplete();
            }
          }
        });
    }
  }

  void _resetCountdown() {
    setState(() {
      _countdown = 5;
      _countdownStarted = false;
    });
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.bodyDetected) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white30, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              color: AppColors.white50,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'ACQUIRING TARGET',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.white70,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Step into frame',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.white50,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    if (!_countdownStarted) {
      return const SizedBox.shrink();
    }

    if (_countdown == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.85),
            border: Border.all(
              color: AppColors.cyberLime,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyberLime.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 1 - _controller.value,
                  strokeWidth: 4,
                  color: AppColors.cyberLime,
                  backgroundColor: AppColors.white20,
                ),
              ),

              // Countdown number
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_countdown',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cyberLime,
                      fontFamily: 'monospace',
                      shadows: [
                        Shadow(
                          color: AppColors.cyberLime.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'LOCK-ON IN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white70,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
