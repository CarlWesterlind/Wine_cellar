import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Shrinks its child slightly while pressed, so a tap feels physical.
/// Keeps the ripple, focus and screen reader support of [InkWell].
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: Motion.of(context, Motion.fast),
      curve: Motion.easeOut,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
        child: widget.child,
      ),
    );
  }
}

/// Fades its child in while it slides a few pixels up, once, when it first
/// appears. [index] staggers items in a list slightly; items further down
/// than the first few appear without animation, so scrolling a long list
/// doesn't replay it on every card.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  static const _maxAnimated = 6;
  static const _stagger = Duration(milliseconds: 30);

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null ||
        Motion.reduced(context) ||
        widget.index >= FadeSlideIn._maxAnimated) {
      return;
    }

    // The delay is part of the animation itself (an Interval) rather than a
    // timer, so it can never fire after the widget is gone.
    final delay = FadeSlideIn._stagger * widget.index;
    final total = delay + Motion.medium;
    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _curve = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.easeOut,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    if (curve == null) return widget.child;
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Text that rolls up to the new value when it changes, e.g. a bottle count.
/// Digits keep the same width so nothing around it jumps.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effective = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.easeOut,
      switchOutCurve: Motion.easeOut,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        // `?current` leaves it out while there is none.
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(text);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: Offset(0, incoming ? 0.5 : -0.5),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(text, key: ValueKey(text), style: effective),
    );
  }
}

/// Cross-fades when [child] is replaced by a child with a different key,
/// with the app's standard timing.
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.easeOut,
      switchOutCurve: Motion.easeOut,
      child: child,
    );
  }
}
