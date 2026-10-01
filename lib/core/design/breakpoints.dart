import 'package:flutter/widgets.dart';

enum WindowSize { compact, medium, expanded }

/// M3 window size classes by width (never by device type).
WindowSize windowSizeFor(double width) {
  if (width < 600) return WindowSize.compact;
  if (width < 840) return WindowSize.medium;
  return WindowSize.expanded;
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize => windowSizeFor(MediaQuery.sizeOf(this).width);
  bool get isCompact => windowSize == WindowSize.compact;
  bool get isExpanded => windowSize == WindowSize.expanded;
  double get gutter => isCompact ? 16 : 24;
}
