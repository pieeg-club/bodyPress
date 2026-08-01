import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/service_providers.dart';
import '../../core/theme/app_theme.dart';

/// Root scaffold with a reader-inspired editorial chapter navigation.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Capture tab (index 2) takes over full-screen like a camera app —
    // hide the floating nav so it doesn't compete.
    final isCaptureTab = navigationShell.currentIndex == 2;

    return Scaffold(
      // Body bleeds under the floating nav bar so the blur has content to blur.
      extendBody: !isCaptureTab,
      body: navigationShell,
      bottomNavigationBar: isCaptureTab
          ? null
          : _ChapterNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              onMoreTap: () => _showMoreSheet(context),
            ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _MoreSheet(routerContext: context),
    );
  }
}

// ─── Nav item metadata ────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.numeral,
    this.isMoreTab = false,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Roman numeral shown as a subtle chapter marker on active tab.
  final String numeral;

  /// When true the tab opens the overflow sheet instead of navigating.
  final bool isMoreTab;
}

const List<_NavItem> _navItems = [
  _NavItem(
    icon: Icons.auto_stories_outlined,
    activeIcon: Icons.auto_stories,
    label: 'Journal',
    numeral: 'I',
  ),
  _NavItem(
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
    label: 'Patterns',
    numeral: 'II',
  ),
  _NavItem(
    icon: Icons.edit_note_rounded,
    activeIcon: Icons.edit_note_rounded,
    label: 'Capture',
    numeral: 'III',
  ),
  _NavItem(
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
    label: 'More',
    numeral: '···',
    isMoreTab: true,
  ),
];

// ─── More-sheet destination model ─────────────────────────────────────────────

class _MoreDestination {
  const _MoreDestination({
    required this.icon,
    required this.label,
    required this.route,
    this.description,
  });
  final IconData icon;
  final String label;
  final String route;
  final String? description;
}

/// Destinations surfaced in the More overflow sheet.
/// Add new features here first; graduate them to [_navItems] when they earn
/// a permanent spot in the primary navigation.
const List<_MoreDestination> _moreDestinations = [
  _MoreDestination(
    icon: Icons.auto_awesome_rounded,
    label: 'AI Services',
    route: '/ai-settings',
    description: 'Choose your AI provider & API keys',
  ),
  _MoreDestination(
    icon: Icons.sensors_rounded,
    label: 'Sensors',
    route: '/sensors',
    description: 'Sensor status & data sources',
  ),
  _MoreDestination(
    icon: Icons.psychology_alt,
    label: 'Signal Sources',
    route: '/sources',
    description: 'BLE signal hardware (EEG, EMG, …)',
  ),
  _MoreDestination(
    icon: Icons.science_outlined,
    label: 'EEG Lab',
    route: '/lab',
    description: 'Record, replay & compare EEG sessions',
  ),
  _MoreDestination(
    icon: Icons.tune_rounded,
    label: 'Environment',
    route: '/environment',
    description: 'Environment & preferences',
  ),
  _MoreDestination(
    icon: Icons.bug_report_outlined,
    label: 'Debug',
    route: '/debug',
    description: 'Developer panel',
  ),
];

// ─── Chapter navigation bar ────────────────────────────────────────────────────

class _ChapterNav extends StatefulWidget {
  const _ChapterNav({
    required this.currentIndex,
    required this.onTap,
    required this.onMoreTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onMoreTap;

  @override
  State<_ChapterNav> createState() => _ChapterNavState();
}

class _ChapterNavState extends State<_ChapterNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final CurvedAnimation _slideAnim;

  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _slideCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_ChapterNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
      _slideCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 10),
      child: SizedBox(
        height: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.deepSea.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.shimmer.withValues(alpha: 0.30),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, _) => _ChapterNavContent(
                  items: _navItems,
                  currentIndex: widget.currentIndex,
                  prevIndex: _prevIndex,
                  slideAnim: _slideAnim,
                  onTap: widget.onTap,
                  onMoreTap: widget.onMoreTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Inner content (rebuilt on animation tick) ───────────────────────────────

class _ChapterNavContent extends StatelessWidget {
  const _ChapterNavContent({
    required this.items,
    required this.currentIndex,
    required this.prevIndex,
    required this.slideAnim,
    required this.onTap,
    required this.onMoreTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final int prevIndex;
  final Animation<double> slideAnim;
  final ValueChanged<int> onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    // Only non-More tabs participate in the active sliding indicator.
    final realCount = items.where((item) => !item.isMoreTab).length;
    final total = items.length;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final itemW = constraints.maxWidth / total;

        // Interpolated x-position of the sliding top rule.
        final fromX = prevIndex * itemW;
        final toX = currentIndex * itemW;
        final lineX = Tween<double>(
          begin: fromX,
          end: toX,
        ).animate(slideAnim).value;

        // The rule inset from each tab edge — gives a refined, editorial gap.
        const lineInset = 22.0;
        const lineH = 1.5;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Glowing top-rule chapter indicator (real tabs only) ──────
            if (currentIndex < realCount)
              Positioned(
                left: lineX + lineInset,
                top: 0,
                width: itemW - lineInset * 2,
                height: lineH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.glow,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.glow.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            // ── Subtle dividers between tabs ──────────────────────────────
            ...List.generate(total - 1, (i) {
              return Positioned(
                left: itemW * (i + 1),
                top: 20,
                bottom: 20,
                width: 0.5,
                child: ColoredBox(
                  color: AppTheme.shimmer.withValues(alpha: 0.40),
                ),
              );
            }),

            // ── Chapter tabs ──────────────────────────────────────────────
            Row(
              children: List.generate(total, (i) {
                final item = items[i];
                final isActive = !item.isMoreTab && i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (item.isMoreTab) {
                        onMoreTap();
                      } else {
                        onTap(i);
                      }
                    },
                    child: item.isMoreTab
                        ? Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              _ChapterTab(item: item, isActive: isActive),
                              const Positioned(
                                right: 16,
                                top: 8,
                                child: _SensorAttentionBadge(),
                              ),
                            ],
                          )
                        : _ChapterTab(item: item, isActive: isActive),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ─── Single chapter tab ──────────────────────────────────────────────────────

class _ChapterTab extends StatelessWidget {
  const _ChapterTab({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppTheme.glow : AppTheme.fog;
    final labelColor = isActive ? AppTheme.moonbeam : AppTheme.fog;
    final numeralColor = isActive
        ? AppTheme.glow.withValues(alpha: 0.70)
        : Colors.transparent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4), // breathing room below the top rule
        // ── Chapter numeral ──────────────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: numeralColor,
            letterSpacing: 1.5,
            fontFamily: 'DM Sans',
          ),
          child: Text(item.numeral),
        ),
        const SizedBox(height: 2),
        // ── Icon ─────────────────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            key: ValueKey(isActive),
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        // ── Label (all-caps editorial) ────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: labelColor,
            letterSpacing: 2.2,
            fontFamily: 'DM Sans',
          ),
          child: Text(item.label.toUpperCase()),
        ),
      ],
    );
  }
}

// ─── More overflow sheet ──────────────────────────────────────────────────────

class _MoreSheet extends ConsumerWidget {
  const _MoreSheet({required this.routerContext});

  /// Context from the shell build — used for go_router navigation.
  final BuildContext routerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.deepSea,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppTheme.shimmer.withValues(alpha: 0.30),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.shimmer.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Section label ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Text(
                    'MORE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.fog,
                      letterSpacing: 2.5,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ),
            ),

            // ── Sensor guidance (when not healthy) ─────────────────────────────
            _SensorGuidanceBanner(ref: ref),

            // ── Destination tiles (scrollable when sheet is short) ─────────
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ..._moreDestinations.map(
                    (dest) => _MoreTile(
                      destination: dest,
                      onTap: () {
                        Navigator.of(context).pop();
                        routerContext.push(dest.route);
                      },
                      badge: dest.route == '/sensors'
                          ? _buildSensorBadgeDot(ref)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.destination, required this.onTap, this.badge});

  final _MoreDestination destination;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.shimmer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(destination.icon, size: 20, color: AppTheme.fog),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  if (destination.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      destination.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.fog,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[badge!, const SizedBox(width: 8)],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.fog.withValues(alpha: 0.50),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sensor attention badge & guidance widgets ───────────────────────────────────

/// Helper — builds a small pulsating dot for the Sensors tile in the More
/// sheet. Returns [SizedBox.shrink] when everything is healthy.
Widget _buildSensorBadgeDot(WidgetRef ref) {
  final available = ref.watch(healthAvailableProvider).valueOrNull;
  final granted = ref.watch(healthPermissionStatusProvider).valueOrNull;

  if (available == null || granted == null) return const SizedBox.shrink();
  if (available && granted) return const SizedBox.shrink();

  final color = !available ? const Color(0xFF60758F) : const Color(0xFFFFBD5A);

  return _PulseDot(color: color, size: 8, needsAttention: !granted);
}

/// Badge overlay for the More tab in the bottom nav — shows a pulsating dot
/// when sensors need attention. Hidden when everything is healthy.
class _SensorAttentionBadge extends ConsumerWidget {
  const _SensorAttentionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(healthAvailableProvider).valueOrNull;
    final granted = ref.watch(healthPermissionStatusProvider).valueOrNull;

    if (available == null || granted == null) return const SizedBox.shrink();
    if (available && granted) return const SizedBox.shrink();

    final color = !available
        ? const Color(0xFF60758F)
        : const Color(0xFFFFBD5A);

    return _PulseDot(color: color, size: 7, needsAttention: !granted);
  }
}

/// Inline guidance banner shown at the top of the More sheet when sensors are
/// not fully healthy. Guides the user towards the Sensors screen.
class _SensorGuidanceBanner extends StatelessWidget {
  const _SensorGuidanceBanner({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(healthAvailableProvider).valueOrNull;
    final granted = ref.watch(healthPermissionStatusProvider).valueOrNull;

    // All good or still loading — no banner.
    if (available == null && granted == null) return const SizedBox.shrink();
    if (available == true && granted == true) return const SizedBox.shrink();

    final String message;
    final Color accent;
    final IconData icon;

    if (available == false) {
      message = 'Health platform unavailable on this device.';
      accent = const Color(0xFF60758F);
      icon = Icons.cloud_off_rounded;
    } else if (granted == false) {
      message = 'Some sensors need attention \u2014 open Sensors to review.';
      accent = const Color(0xFFFFBD5A);
      icon = Icons.warning_amber_rounded;
    } else {
      message = 'Checking sensor status\u2026';
      accent = const Color(0xFF60758F);
      icon = Icons.hourglass_empty_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            _PulseDot(
              color: accent,
              size: 10,
              needsAttention: granted == false,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: accent,
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsating dot indicator that draws attention when sensors are unhealthy.
class _PulseDot extends StatefulWidget {
  const _PulseDot({
    required this.color,
    this.size = 9,
    this.needsAttention = false,
  });
  final Color color;
  final double size;
  final bool needsAttention;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.needsAttention) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.needsAttention && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.needsAttention && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = widget.needsAttention ? 1.0 + _ctrl.value * 0.35 : 1.0;
        final opacity = widget.needsAttention ? 0.5 + _ctrl.value * 0.5 : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: opacity),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
