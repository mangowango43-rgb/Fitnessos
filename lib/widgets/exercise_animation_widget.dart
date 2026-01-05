import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/exercise_media_service.dart';
import '../utils/app_colors.dart';

/// =============================================================================
/// EXERCISE ANIMATION WIDGET
/// =============================================================================
/// Displays exercise GIF/animation with smart loading and caching
/// 
/// Features:
/// - Only loads when visible (battery optimization)
/// - Cached images (no repeated downloads)
/// - Pattern-based fallbacks
/// - Loading shimmer effect
/// =============================================================================

class ExerciseAnimationWidget extends StatefulWidget {
  final String exerciseId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoPlay;
  final BorderRadius? borderRadius;

  const ExerciseAnimationWidget({
    super.key,
    required this.exerciseId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.borderRadius,
  });

  @override
  State<ExerciseAnimationWidget> createState() => _ExerciseAnimationWidgetState();
}

class _ExerciseAnimationWidgetState extends State<ExerciseAnimationWidget> {
  final ExerciseMediaService _mediaService = ExerciseMediaService();
  String? _animationUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    try {
      final url = await _mediaService.getAnimationUrl(widget.exerciseId);
      if (mounted) {
        setState(() {
          _animationUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('⚠️ Error loading animation for ${widget.exerciseId}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        color: AppColors.white5,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        child: _isLoading
            ? _buildLoadingShimmer()
            : _animationUrl != null
                ? CachedNetworkImage(
                    imageUrl: _animationUrl!,
                    width: widget.width,
                    height: widget.height,
                    fit: widget.fit,
                    placeholder: (context, url) => _buildLoadingShimmer(),
                    errorWidget: (context, url, error) => _buildErrorWidget(),
                  )
                : _buildErrorWidget(),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white5,
            AppColors.white10,
            AppColors.white5,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.cyberLime),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppColors.white5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            color: AppColors.white30,
            size: widget.height != null ? widget.height! * 0.4 : 48,
          ),
          const SizedBox(height: 8),
          Text(
            widget.exerciseId.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              color: AppColors.white30,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Small circular animation (for lists)
class ExerciseAnimationCircle extends StatelessWidget {
  final String exerciseId;
  final double size;

  const ExerciseAnimationCircle({
    super.key,
    required this.exerciseId,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseAnimationWidget(
      exerciseId: exerciseId,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

/// Large animation preview (for lock screen)
class ExerciseAnimationPreview extends StatelessWidget {
  final String exerciseId;
  final String? exerciseName;

  const ExerciseAnimationPreview({
    super.key,
    required this.exerciseId,
    this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white10,
            AppColors.white5,
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ExerciseAnimationWidget(
              exerciseId: exerciseId,
              fit: BoxFit.contain,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          if (exerciseName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white5,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Text(
                exerciseName!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Picture-in-Picture animation (for training HUD)
class ExerciseAnimationPIP extends StatelessWidget {
  final String exerciseId;

  const ExerciseAnimationPIP({
    super.key,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyberLime.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ExerciseAnimationWidget(
        exerciseId: exerciseId,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

