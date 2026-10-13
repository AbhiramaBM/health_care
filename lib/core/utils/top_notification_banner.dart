import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../theme/app_theme.dart';
import '../../screens/alerts/alerts_screen.dart';

/// Top-level navigator key for accessing root overlay across the entire application.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// WhatsApp-style compact floating in-app notification banner.
///
/// Appears smoothly at the top of the screen, allows normal app interaction,
/// auto-dismisses after 3–5 seconds, can be swiped up or tapped, and never blocks
/// user interaction.
class TopNotificationBanner {
  TopNotificationBanner._();

  static OverlayEntry? _currentEntry;
  static _BannerController? _activeController;

  /// Shows a compact floating top notification banner.
  static void show({
    BuildContext? context,
    required String title,
    required String message,
    String? timestamp,
    Widget? icon,
    Color? accentColor,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final effectiveContext = context ?? rootNavigatorKey.currentContext;
    if (effectiveContext == null) return;

    final overlay = Overlay.maybeOf(effectiveContext, rootOverlay: true) ??
        rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final color = accentColor ?? AppTheme.primaryColor;
    final timeStr = timestamp ?? 'Just now';

    // If an existing banner is already visible, update its content & reset timer
    if (_activeController != null && _activeController!.isMounted) {
      _activeController!.update(
        title: title,
        message: message,
        timestamp: timeStr,
        icon: icon,
        accentColor: color,
        onTap: onTap,
        duration: duration,
      );
      return;
    }

    _dismissCurrent();

    late final OverlayEntry entry;
    final controller = _BannerController();
    _activeController = controller;

    entry = OverlayEntry(
      builder: (ctx) {
        final topPadding = MediaQuery.of(ctx).padding.top;
        return Positioned(
          top: topPadding + 8,
          left: 12,
          right: 12,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _NotificationBannerWidget(
                controller: controller,
                initialTitle: title,
                initialMessage: message,
                initialTimestamp: timeStr,
                initialIcon: icon,
                initialColor: color,
                initialOnTap: onTap,
                duration: duration,
                onDismissed: () {
                  if (_currentEntry == entry) {
                    _currentEntry?.remove();
                    _currentEntry = null;
                    _activeController = null;
                  }
                },
              ),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Convenience method to show a compact banner for clinical AlertModel.
  static void showAlert(
    BuildContext? context,
    AlertModel alert, {
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final color = _getSeverityColor(alert.severity);

    show(
      context: context,
      title: alert.displayTitle,
      message: alert.displayDescription,
      timestamp: 'Just now',
      accentColor: color,
      icon: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications_active_rounded,
          color: color,
          size: 18,
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          final nav = rootNavigatorKey.currentState ??
              (context != null ? Navigator.maybeOf(context) : null);
          nav?.push(
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          );
        }
      },
      duration: duration,
    );
  }

  /// Dismisses any currently visible notification banner immediately.
  static void dismiss() {
    _dismissCurrent();
  }

  static void _dismissCurrent() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
    _activeController = null;
  }

  static Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
      case 'URGENT':
        return AppTheme.criticalRed;
      case 'HIGH':
      case 'WATCH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return AppTheme.warningAmber;
      case 'LOW':
      case 'INFO':
      default:
        return AppTheme.infoBlue;
    }
  }
}

class _BannerController {
  bool isMounted = false;
  void Function({
    required String title,
    required String message,
    required String timestamp,
    Widget? icon,
    Color? accentColor,
    VoidCallback? onTap,
    required Duration duration,
  })? _updateCallback;

  void update({
    required String title,
    required String message,
    required String timestamp,
    Widget? icon,
    Color? accentColor,
    VoidCallback? onTap,
    required Duration duration,
  }) {
    _updateCallback?.call(
      title: title,
      message: message,
      timestamp: timestamp,
      icon: icon,
      accentColor: accentColor,
      onTap: onTap,
      duration: duration,
    );
  }
}

class _NotificationBannerWidget extends StatefulWidget {
  final _BannerController controller;
  final String initialTitle;
  final String initialMessage;
  final String initialTimestamp;
  final Widget? initialIcon;
  final Color initialColor;
  final VoidCallback? initialOnTap;
  final Duration duration;
  final VoidCallback onDismissed;

  const _NotificationBannerWidget({
    required this.controller,
    required this.initialTitle,
    required this.initialMessage,
    required this.initialTimestamp,
    this.initialIcon,
    required this.initialColor,
    this.initialOnTap,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  Timer? _dismissTimer;

  late String _title;
  late String _message;
  late String _timestamp;
  Widget? _icon;
  late Color _accentColor;
  VoidCallback? _onTap;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _message = widget.initialMessage;
    _timestamp = widget.initialTimestamp;
    _icon = widget.initialIcon;
    _accentColor = widget.initialColor;
    _onTap = widget.initialOnTap;

    widget.controller.isMounted = true;
    widget.controller._updateCallback = _handleUpdate;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _animController.forward();
    _startTimer(widget.duration);
  }

  void _handleUpdate({
    required String title,
    required String message,
    required String timestamp,
    Widget? icon,
    Color? accentColor,
    VoidCallback? onTap,
    required Duration duration,
  }) {
    if (!mounted) return;
    setState(() {
      _title = title;
      _message = message;
      _timestamp = timestamp;
      _icon = icon;
      if (accentColor != null) _accentColor = accentColor;
      _onTap = onTap;
    });
    _startTimer(duration);
  }

  void _startTimer(Duration duration) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (!mounted) {
      widget.onDismissed();
      return;
    }
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.isMounted = false;
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            // Swipe up to dismiss
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -100) {
              _dismiss();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _dismissTimer?.cancel();
                _dismiss();
                _onTap?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar / Icon
                    if (_icon != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: _icon!,
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: _accentColor,
                            size: 18,
                          ),
                        ),
                      ),

                    // Content: Title & Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _timestamp,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _message,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
