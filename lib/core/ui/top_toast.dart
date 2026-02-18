import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_init_project/core/theme/tweakcn_theme.g.dart';

OverlayEntry? _activeToastEntry;

extension TopToastExtension on BuildContext {
  void showTopToast(String message) {
    final colors = tweakcnColors;

    _activeToastEntry?.remove();
    _activeToastEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopToast(
        message: message,
        colors: colors,
        onDismissed: () {
          entry.remove();
          if (_activeToastEntry == entry) _activeToastEntry = null;
        },
      ),
    );
    _activeToastEntry = entry;
    Overlay.of(this).insert(entry);
  }
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.colors,
    required this.onDismissed,
  });

  final String message;
  final TweakcnColors colors;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  double _dragOffset = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    Future.delayed(const Duration(seconds: 2), _dismiss);
  }

  void _dismiss() {
    if (!mounted || _dismissing) return;
    _dismissing = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8.h + _dragOffset,
      left: 20.w,
      right: 20.w,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() => _dragOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset.abs() > 30) {
            _dismiss();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: widget.colors.card,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: widget.colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: widget.colors.mutedForeground,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.colors.foreground,
                        fontSize: 13.sp,
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
    );
  }
}
