import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/strings_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive_content.dart';

/// One page's fixed content — icon, title, body. Built fresh in [build]
/// (not cached) since it reads localized strings off [AppStrings].
class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// The first-launch "stories" tutorial explaining how the app's astronomy
/// metaphor fits together — victories/goals/dead stars, pulsars (habits),
/// constellations (projects), and supernovas (life areas). Shown once
/// automatically (see `OnboardingPrefs`, checked in `main.dart`), and
/// replayable from Settings' Data section in debug builds only.
///
/// Tap the left/right half of a page (or swipe, since it's a plain
/// [PageView] under the hood) to move between pages; the bottom button does
/// the same, ending in "Get started" on the last page. The close button in
/// the corner skips straight out. Either way, popping this screen is the
/// only signal `main.dart` needs to mark onboarding as seen — there's no
/// separate "did they finish" state to track.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OnboardingPage> _pages(AppStrings strings) => [
    _OnboardingPage(
      icon: Icons.nights_stay,
      title: strings.onboardingIntroTitle,
      body: strings.onboardingIntroBody,
    ),
    _OnboardingPage(
      icon: Icons.star,
      title: strings.onboardingVictoriesTitle,
      body: strings.onboardingVictoriesBody,
    ),
    _OnboardingPage(
      icon: Icons.flag_outlined,
      title: strings.onboardingGoalsTitle,
      body: strings.onboardingGoalsBody,
    ),
    _OnboardingPage(
      icon: Icons.repeat,
      title: strings.onboardingHabitsTitle,
      body: strings.onboardingHabitsBody,
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome,
      title: strings.onboardingConstellationsTitle,
      body: strings.onboardingConstellationsBody,
    ),
    _OnboardingPage(
      icon: Icons.flare,
      title: strings.onboardingAreasTitle,
      body: strings.onboardingAreasBody,
    ),
    _OnboardingPage(
      icon: Icons.rocket_launch,
      title: strings.onboardingOutroTitle,
      body: strings.onboardingOutroBody,
    ),
  ];

  void _next(int pageCount) {
    if (_index >= pageCount - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final pages = _pages(strings);

    return Scaffold(
      backgroundColor: colors.night,
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < pages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= _index
                                ? colors.gold
                                : colors.nightBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: strings.onboardingSkipTooltip,
                    icon: Icon(Icons.close, color: colors.muted),
                  ),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    final width = MediaQuery.sizeOf(context).width;
                    if (details.globalPosition.dx < width / 2) {
                      _previous();
                    } else {
                      _next(pages.length);
                    }
                  },
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _OnboardingPageBody(page: pages[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _next(pages.length),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.gold,
                      foregroundColor: colors.onGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _index == pages.length - 1
                          ? strings.onboardingGetStartedAction
                          : strings.onboardingNextAction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageBody extends StatelessWidget {
  const _OnboardingPageBody({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, color: colors.gold, size: 44),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
