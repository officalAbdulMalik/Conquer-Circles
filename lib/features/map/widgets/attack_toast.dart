import 'dart:async';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enum & Config
// ---------------------------------------------------------------------------

enum AttackToastVariant {
  claimed,
  captured,
  damaged,
  reinforced,
  protected,
  cooldown,
  noEnergy,
  restricted,
  generic,
}

extension _AttackToastVariantExt on AttackToastVariant {
  String get emoji {
    switch (this) {
      case AttackToastVariant.claimed:
        return '🏴';
      case AttackToastVariant.captured:
        return '⚔️';
      case AttackToastVariant.damaged:
        return '💥';
      case AttackToastVariant.reinforced:
        return '🧱';
      case AttackToastVariant.protected:
        return '🛡️';
      case AttackToastVariant.cooldown:
        return '⏱️';
      case AttackToastVariant.noEnergy:
        return '⚡';
      case AttackToastVariant.restricted:
        return '🚫';
      case AttackToastVariant.generic:
        return '🔔';
    }
  }

  Color get bg {
    switch (this) {
      case AttackToastVariant.claimed:
        return const Color(0xFF0D47A1);
      case AttackToastVariant.captured:
        return const Color(0xFF1B5E20);
      case AttackToastVariant.damaged:
        return const Color(0xFFBF360C);
      case AttackToastVariant.reinforced:
        return const Color(0xFF0B3D2E);
      case AttackToastVariant.protected:
        return const Color(0xFF4A148C);
      case AttackToastVariant.cooldown:
        return const Color(0xFF212121);
      case AttackToastVariant.noEnergy:
        return const Color(0xFFB71C1C);
      case AttackToastVariant.restricted:
        return const Color(0xFF263238);
      case AttackToastVariant.generic:
        return const Color(0xFF1E88E5);
    }
  }

  Color get border {
    switch (this) {
      case AttackToastVariant.claimed:
        return const Color(0xFF2196F3);
      case AttackToastVariant.captured:
        return const Color(0xFF4CAF50);
      case AttackToastVariant.damaged:
        return const Color(0xFFFF5722);
      case AttackToastVariant.reinforced:
        return const Color(0xFF26A69A);
      case AttackToastVariant.protected:
        return const Color(0xFF9C27B0);
      case AttackToastVariant.cooldown:
        return const Color(0xFF757575);
      case AttackToastVariant.noEnergy:
        return const Color(0xFFF44336);
      case AttackToastVariant.restricted:
        return const Color(0xFF90A4AE);
      case AttackToastVariant.generic:
        return const Color(0xFF64B5F6);
    }
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Call [AttackToastController.show] to display a toast over the map.
/// Place an [AttackToastOverlay] in the widget tree and pass this controller.
class AttackToastController extends ChangeNotifier {
  AttackToastVariant? _variant;
  String? _message;

  AttackToastVariant? get variant => _variant;
  String? get message => _message;

  void show(AttackToastVariant variant, String message) {
    _variant = variant;
    _message = message;
    notifyListeners();
  }

  void clear() {
    _variant = null;
    _message = null;
    notifyListeners();
  }

  /// Convenience factory that maps a [claimOrAttackTile] result map to
  /// the correct variant and message.
  static AttackToastVariant? variantFromAction(String action) {
    switch (action) {
      case 'claimed':
        return AttackToastVariant.claimed;
      case 'captured':
        return AttackToastVariant.captured;
      case 'damaged':
        return AttackToastVariant.damaged;
      case 'reinforced':
        return AttackToastVariant.reinforced;
      case 'protected':
      case 'shielded':
        return AttackToastVariant.restricted;
      case 'cooldown':
        return AttackToastVariant.cooldown;
      case 'no_energy':
        return AttackToastVariant.noEnergy;
      case 'error':
        return AttackToastVariant.restricted;
      default:
        return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------------------

class AttackToastOverlay extends StatefulWidget {
  final AttackToastController controller;

  const AttackToastOverlay({super.key, required this.controller});

  @override
  State<AttackToastOverlay> createState() => _AttackToastOverlayState();
}

class _AttackToastOverlayState extends State<AttackToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _hideTimer;

  AttackToastVariant? _currentVariant;
  String? _currentMessage;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final variant = widget.controller.variant;
    final message = widget.controller.message;

    if (variant != null && message != null) {
      setState(() {
        _currentVariant = variant;
        _currentMessage = message;
      });
      _hideTimer?.cancel();
      _animController.forward(from: 0).then((_) {
        _hideTimer = Timer(const Duration(milliseconds: 3500), () {
          if (mounted) {
            _animController.reverse().then((_) {
              widget.controller.clear();
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onControllerUpdate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVariant == null) return const SizedBox.shrink();

    final variant = _currentVariant!;

    if (variant == AttackToastVariant.cooldown) {
      return SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _CooldownToastCard(
            message: _currentMessage ?? '29 minutes remaining',
            onClose: _dismiss,
          ),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Container(
            width: 280,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: variant.bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: variant.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: variant.border.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(variant.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _currentMessage ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    _hideTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) widget.controller.clear();
    });
  }
}

class _CooldownToastCard extends StatelessWidget {
  const _CooldownToastCard({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.alarm,
                color: Color(0xFF4169FF),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cooldown Time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A94A6),
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Color(0xFF111827)),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
