import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enum & Config
// ---------------------------------------------------------------------------

enum AttackToastVariant {
  claimed,
  captured,
  damaged,
  protected,
  cooldown,
  noEnergy,
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
      case AttackToastVariant.protected:
        return '🛡️';
      case AttackToastVariant.cooldown:
        return '⏱️';
      case AttackToastVariant.noEnergy:
        return '⚡';
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
      case AttackToastVariant.protected:
        return const Color(0xFF4A148C);
      case AttackToastVariant.cooldown:
        return const Color(0xFF212121);
      case AttackToastVariant.noEnergy:
        return const Color(0xFFB71C1C);
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
      case AttackToastVariant.protected:
        return const Color(0xFF9C27B0);
      case AttackToastVariant.cooldown:
        return const Color(0xFF757575);
      case AttackToastVariant.noEnergy:
        return const Color(0xFFF44336);
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
      case 'protected':
        return AttackToastVariant.protected;
      case 'cooldown':
        return AttackToastVariant.cooldown;
      case 'no_energy':
        return AttackToastVariant.noEnergy;
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
      _animController.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 2500), () {
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
    widget.controller.removeListener(_onControllerUpdate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVariant == null) return const SizedBox.shrink();

    final variant = _currentVariant!;

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
}
