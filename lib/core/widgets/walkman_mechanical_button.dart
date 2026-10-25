import 'package:flutter/material.dart';
import 'package:spool/core/constants/app_colors.dart';
import 'package:spool/core/constants/app_typography.dart';
import 'package:spool/core/services/mechanical_sound_service.dart';
import 'package:spool/features/settings/domain/app_settings.dart';

class WalkmanMechanicalButton extends StatefulWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDepressed;
  final MechanicalSoundType soundType;
  final AppSettings settings;
  final double width;
  final double height;
  final Color? accentColor;
  final bool isPrimary;

  const WalkmanMechanicalButton({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.isDepressed = false,
    this.soundType = MechanicalSoundType.skipClick,
    required this.settings,
    this.width = 54,
    this.height = 68,
    this.accentColor,
    this.isPrimary = false,
  });

  @override
  State<WalkmanMechanicalButton> createState() => _WalkmanMechanicalButtonState();
}

class _WalkmanMechanicalButtonState extends State<WalkmanMechanicalButton> {
  bool _isPressedDown = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressedDown = true);
    // Instant mechanical audio & haptic trigger!
    MechanicalSoundService.instance.playMechanicalSound(
      widget.soundType,
      settings: widget.settings,
    );
    // Instant playback command execution!
    widget.onPressed();
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressedDown = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressedDown = false);
  }

  @override
  Widget build(BuildContext context) {
    final active = _isPressedDown || widget.isDepressed;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, active ? 3.5 : 0, 0),
        decoration: BoxDecoration(
          // Bevelled Walkman metallic button appearance
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: active
                ? [
                    const Color(0xFF888890),
                    const Color(0xFF6A6A72),
                  ]
                : [
                    const Color(0xFFE8E8ED),
                    const Color(0xFFBEBEC8),
                  ],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? const Color(0xFF55555C) : const Color(0xFFFFFFFF),
            width: 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(200),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha(80),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null)
              Icon(
                widget.icon,
                size: widget.isPrimary ? 24 : 18,
                color: widget.accentColor ?? (active ? AppColors.neonOrange : const Color(0xFF222226)),
              ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: AppTypography.monoSmall.copyWith(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: active ? Colors.black : const Color(0xFF33333A),
                letterSpacing: 0.5,
              ),
            ),
            // Tactile indicator line under button
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 16,
              height: 1.5,
              color: active ? AppColors.neonOrange : const Color(0xFF888892),
            ),
          ],
        ),
      ),
    );
  }
}
