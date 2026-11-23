import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fullxpet/core/services/nav_service.dart';
import 'package:fullxpet/common/l10n/app_localizations.dart';

enum AppToastType { success, error, warning, info }

enum AppToastPosition { top, center, bottom }

OverlayEntry? _toastEntry;
ValueNotifier<bool>? _toastVisible;
Timer? _toastTimer;

void _clearToast() {
  _toastTimer?.cancel();
  _toastTimer = null;
  try {
    _toastEntry?.remove();
  } catch (_) {}
  _toastEntry = null;
  _toastVisible?.dispose();
  _toastVisible = null;
}

extension AppDialogExtension on BuildContext {
  Future<bool?> showAppDialog({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
  }) {
    final confirmLabel = confirmText ?? S.of(this)!.confirm;
    final cancelLabel = cancelText ?? S.of(this)!.cancel;
    return showDialog<bool>(
      context: this,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Color(0xFF917CEE), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void showAppToast({
    required String message,
    required AppToastType type,
    AppToastPosition position = AppToastPosition.bottom,
    Duration duration = const Duration(seconds: 2),
  }) {
    final dotColor = switch (type) {
      AppToastType.success => const Color(0xFF8CC152),
      AppToastType.error => const Color(0xFFE56B6F),
      AppToastType.warning => const Color(0xFFE6A23C),
      AppToastType.info => const Color(0xFF917CEE),
    };

    final overlay = Overlay.maybeOf(this, rootOverlay: true) ?? NavService.rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _clearToast();

    final visible = ValueNotifier<bool>(false);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final kb = MediaQuery.viewInsetsOf(ctx).bottom;
        final (alignment, padding) = switch (position) {
          AppToastPosition.top => (Alignment.topCenter, const EdgeInsets.fromLTRB(24, kToolbarHeight + 12, 24, 0)),
          AppToastPosition.center => (Alignment.center, const EdgeInsets.symmetric(horizontal: 28)),
          AppToastPosition.bottom => (Alignment.bottomCenter, EdgeInsets.fromLTRB(24, 0, 24, 84 + kb)),
        };

        return SafeArea(
          child: IgnorePointer(
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: padding,
                child: ValueListenableBuilder<bool>(
                  valueListenable: visible,
                  builder: (_, show, child) =>
                      AnimatedOpacity(opacity: show ? 1 : 0, duration: const Duration(milliseconds: 180), child: child),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      overlay.insert(entry);
    } catch (_) {
      visible.dispose();
      return;
    }

    _toastEntry = entry;
    _toastVisible = visible;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (identical(_toastEntry, entry)) visible.value = true;
    });

    _toastTimer = Timer(duration, () {
      if (!identical(_toastEntry, entry)) return;
      visible.value = false;
      _toastTimer = Timer(const Duration(milliseconds: 200), () {
        if (identical(_toastEntry, entry)) _clearToast();
      });
    });
  }
}
