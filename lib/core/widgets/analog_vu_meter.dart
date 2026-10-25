import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AnalogVuMeter extends StatefulWidget {
  final bool isPlaying;

  const AnalogVuMeter({super.key, required this.isPlaying});

  @override
  State<AnalogVuMeter> createState() => _AnalogVuMeterState();
}

class _AnalogVuMeterState extends State<AnalogVuMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final math.Random _random = math.Random();
  double _leftLevel = 0.0;
  double _rightLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_updateLevels);

    if (widget.isPlaying) {
      _animController.repeat(reverse: true);
    }
  }

  void _updateLevels() {
    if (!widget.isPlaying) {
      if (_leftLevel > 0.05 || _rightLevel > 0.05) {
        setState(() {
          _leftLevel *= 0.8;
          _rightLevel *= 0.8;
        });
      }
      return;
    }

    setState(() {
      _leftLevel = 0.3 + (_random.nextDouble() * 0.55);
      _rightLevel = 0.3 + (_random.nextDouble() * 0.55);
    });
  }

  @override
  void didUpdateWidget(covariant AnalogVuMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
        setState(() {
          _leftLevel = 0.0;
          _rightLevel = 0.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131317),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('VU', style: AppTypography.monoSmall.copyWith(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          _buildMeterBar('L', _leftLevel),
          const SizedBox(width: 10),
          _buildMeterBar('R', _rightLevel),
        ],
      ),
    );
  }

  Widget _buildMeterBar(String channel, double level) {
    return Row(
      children: [
        Text(
          channel,
          style: AppTypography.monoSmall.copyWith(fontSize: 8, color: AppColors.textMuted),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 44,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Row(
              children: [
                // Green segment (normal)
                Expanded(
                  flex: 6,
                  child: Container(
                    color: level > 0.1 ? AppColors.tapeGreen : const Color(0xFF1E281E),
                  ),
                ),
                const SizedBox(width: 1),
                // Amber segment (headroom)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: level > 0.6 ? AppColors.tapeAmber : const Color(0xFF28241E),
                  ),
                ),
                const SizedBox(width: 1),
                // Red segment (peak)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: level > 0.85 ? AppColors.vinylRed : const Color(0xFF2D1818),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
