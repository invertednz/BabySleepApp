import 'package:flutter/material.dart';

/// Animation utilities for the entire app following design guidelines:
/// - Page transitions: 300ms cross-fade
/// - Staggered cards: 600ms fade+slide with 100ms delays
/// - Micro-interactions: 150-250ms
/// - Respects prefers-reduced-motion
/// 
/// Can be used in onboarding, main app screens, modals, and anywhere
/// consistent animations are needed.

class AppAnimations {
  // Page transition constants
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOut;

  // Staggered element constants
  static const Duration staggerElementDuration = Duration(milliseconds: 600);
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Curve staggerCurve = Curves.easeOut;
  static const double staggerSlideOffset = 0.3; // 30% down from final position

  // Micro-interaction constants
  static const Duration microInteractionDuration = Duration(milliseconds: 200);
  static const Curve microInteractionCurve = Curves.easeOut;

  // Modal/overlay constants
  static const Duration modalDuration = Duration(milliseconds: 300);
  static const Curve modalCurve = Curves.easeOut;

  // Toast/alert constants
  static const Duration toastDuration = Duration(milliseconds: 250);
  static const Curve toastCurve = Curves.easeInOut;

  /// Creates a cross-fade page route transition (300ms, ease-in-out)
  /// Use for navigating between onboarding screens
  static PageRouteBuilder<T> createPageRoute<T>({
    required Widget page,
    bool respectReducedMotion = true,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: pageTransitionDuration,
      reverseTransitionDuration: pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Respect reduced motion preference
        if (respectReducedMotion && 
            MediaQuery.of(context).disableAnimations) {
          return child;
        }

        // Cross-fade transition
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: pageTransitionCurve,
          ),
          child: child,
        );
      },
    );
  }

  /// Creates a staggered fade + slide-up animation for list items/cards
  /// Duration: 600ms, Curve: ease-out, Delay: index * 100ms
  static Widget createStaggeredCard({
    required Widget child,
    required int index,
    required AnimationController controller,
    int maxElements = 7,
    bool respectReducedMotion = true,
  }) {
    // Limit stagger to prevent long waits
    final effectiveIndex = index.clamp(0, maxElements - 1);
    
    final delay = staggerDelay.inMilliseconds * effectiveIndex;
    final totalDuration = controller.duration?.inMilliseconds ?? 1000;
    
    // Calculate animation intervals
    final startTime = delay / totalDuration;
    final endTime = ((delay + staggerElementDuration.inMilliseconds) / totalDuration).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        startTime,
        endTime,
        curve: staggerCurve,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Respect reduced motion
        if (respectReducedMotion && MediaQuery.of(context).disableAnimations) {
          return child!;
        }

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, staggerSlideOffset * 100 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Widget that automatically handles staggered animations for its children
class StaggeredAnimationList extends StatefulWidget {
  final List<Widget> children;
  final int maxStaggerElements;
  final bool respectReducedMotion;
  final Duration? customDuration;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.maxStaggerElements = 7,
    this.respectReducedMotion = true,
    this.customDuration,
  });

  @override
  State<StaggeredAnimationList> createState() => _StaggeredAnimationListState();
}

class _StaggeredAnimationListState extends State<StaggeredAnimationList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    // Calculate total duration: last element delay + element duration
    final maxDelay = AppAnimations.staggerDelay.inMilliseconds * 
        (widget.maxStaggerElements - 1);
    final totalMs = maxDelay + AppAnimations.staggerElementDuration.inMilliseconds;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.customDuration ?? Duration(milliseconds: totalMs),
    );
    
    // Start animation on mount
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        return AppAnimations.createStaggeredCard(
          child: entry.value,
          index: entry.key,
          controller: _controller,
          maxElements: widget.maxStaggerElements,
          respectReducedMotion: widget.respectReducedMotion,
        );
      }).toList(),
    );
  }
}

/// Extension to easily navigate with cross-fade transition
/// Works for both onboarding and main app navigation
extension AppNavigator on NavigatorState {
  /// Push with cross-fade transition (300ms)
  Future<T?> pushWithFade<T extends Object?>(Widget page) {
    return push<T>(AppAnimations.createPageRoute<T>(page: page));
  }

  /// Push replacement with cross-fade transition (300ms)
  Future<T?> pushReplacementWithFade<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      AppAnimations.createPageRoute<T>(page: page),
      result: result,
    );
  }
}

/// Backward compatibility - alias for existing onboarding code
@Deprecated('Use AppAnimations instead')
class OnboardingAnimations {
  static const Duration pageTransitionDuration = AppAnimations.pageTransitionDuration;
  static const Curve pageTransitionCurve = AppAnimations.pageTransitionCurve;
  static const Duration staggerElementDuration = AppAnimations.staggerElementDuration;
  static const Duration staggerDelay = AppAnimations.staggerDelay;
  static const Curve staggerCurve = AppAnimations.staggerCurve;
  static const double staggerSlideOffset = AppAnimations.staggerSlideOffset;

  static PageRouteBuilder<T> createPageRoute<T>({
    required Widget page,
    bool respectReducedMotion = true,
  }) => AppAnimations.createPageRoute<T>(page: page, respectReducedMotion: respectReducedMotion);

  static Widget createStaggeredCard({
    required Widget child,
    required int index,
    required AnimationController controller,
    int maxElements = 7,
    bool respectReducedMotion = true,
  }) => AppAnimations.createStaggeredCard(
    child: child,
    index: index,
    controller: controller,
    maxElements: maxElements,
    respectReducedMotion: respectReducedMotion,
  );
}

/// Backward compatibility - alias for existing onboarding code
@Deprecated('Use AppNavigator instead')
extension OnboardingNavigator on NavigatorState {
  Future<T?> pushWithFade<T extends Object?>(Widget page) {
    return push<T>(AppAnimations.createPageRoute<T>(page: page));
  }

  Future<T?> pushReplacementWithFade<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      AppAnimations.createPageRoute<T>(page: page),
      result: result,
    );
  }
}
