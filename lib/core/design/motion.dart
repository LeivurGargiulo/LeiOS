import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Reduce-motion aware helpers (spec §9.8): everything is instant when the
/// platform asks to disable animations.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Duration motionDuration(BuildContext context, [Duration d = Dur.short]) =>
    reduceMotion(context) ? Duration.zero : d;
