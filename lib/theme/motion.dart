import 'package:flutter/widgets.dart';

/// Timing for all animations in the app, so they feel like one family.
///
/// Rules (from Emil Kowalski's animations.dev):
/// - Things entering or leaving use [easeOut]: fast start, gentle stop.
/// - Things moving on screen use [easeInOut].
/// - Keep UI animations under 300 ms.
/// - When the user has asked the phone to reduce motion, animate nothing.
abstract final class Motion {
  /// Button presses, small state changes.
  static const fast = Duration(milliseconds: 150);

  /// Most transitions: fades, chips, list items.
  static const medium = Duration(milliseconds: 220);

  /// Page transitions.
  static const page = Duration(milliseconds: 280);

  /// ease-out-quint: responsive and smooth.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// ease-in-out-cubic: for elements that move while visible.
  static const easeInOut = Cubic(0.645, 0.045, 0.355, 1);

  /// True if the user has turned off animations on their device.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero if the user has turned off animations.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
