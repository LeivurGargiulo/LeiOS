import 'package:flutter/material.dart' show Curves, Easing;
import 'package:flutter/widgets.dart' show Curve;

/// Spacing scale (spec §9.2).
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Dur {
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const long = Duration(milliseconds: 350);
}

abstract final class Ease {
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exit = Easing.emphasizedAccelerate;
  static const Curve inPlace = Curves.easeInOutCubic;
}

abstract final class Layout {
  static const double gutterCompact = 16;
  static const double gutterMedium = 24;
  static const double maxContentWidth = 720;
  static const double maxSettingsWidth = 640;
  static const double maxAuthWidth = 400;
  static const double maxSheetWidth = 560;
  static const double fabClearance = 88;
  static const double masterMin = 360;
  static const double masterMax = 440;
  static const double minTouch = 48;
}

/// Width of the master (list) pane: `clamp(360, 40% of width, 440)`.
double masterPaneWidth(double contentWidth) =>
    (contentWidth * 0.4).clamp(Layout.masterMin, Layout.masterMax).toDouble();
