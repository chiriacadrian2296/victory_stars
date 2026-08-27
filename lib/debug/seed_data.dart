import 'dart:math';

import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../models/life_area.dart';

/// How many wins each seed project gains every time [seedSampleData] runs.
const winsPerSeedTap = 12;

/// Debug-only helper: grows a fixed set of lorem-ipsum projects spread
/// across most areas, so the Sky/constellation UI can be explored without
/// hand-entering data. Idempotent on the *project* level — re-running finds
/// each project by name and reuses it instead of creating a duplicate — but
/// always appends [winsPerSeedTap] fresh wins to every one of them, so
/// repeated taps grow every constellation in step (and, after enough taps,
/// walk each one past its shape's slot capacity into the overflow
/// fallback). Spiritual is left with no seed project, to exercise that
/// area's empty state. Not wired into any release path — only ever called
/// from a kDebugMode-gated button.
Future<void> seedSampleData({
  required WinRepository winRepository,
  required ProjectRepository projectRepository,
}) async {
  final random = Random();
  final existingByName = {
    for (final project in projectRepository.getAll()) project.name: project,
  };

  for (final spec in _specs) {
    var project = existingByName[spec.name];
    project ??= await projectRepository.add(name: spec.name, area: spec.area, iconSlug: spec.iconSlug);

    for (var i = 0; i < winsPerSeedTap; i++) {
      await winRepository.add(
        title: _loremTitle(random),
        description: _loremDescription(random),
        projectId: project.id,
      );
      // Win ids are millisecondsSinceEpoch; a tight loop without this could
      // mint duplicate ids, which every id-based lookup in the app assumes
      // can't happen.
      await Future.delayed(const Duration(milliseconds: 2));
    }
  }
}

class _ProjectSeed {
  const _ProjectSeed(this.name, this.area, this.iconSlug);
  final String name;
  final LifeArea area;
  final String iconSlug;
}

const _specs = [
  _ProjectSeed('Run a 10k', LifeArea.physical, 'fitness_center'),
  _ProjectSeed('Learn to swim', LifeArea.physical, 'pool'),
  _ProjectSeed('Daily meditation', LifeArea.psychological, 'spa'),
  _ProjectSeed('Build this app', LifeArea.professional, 'rocket_launch'),
  _ProjectSeed('Find a new job', LifeArea.professional, 'work'),
  _ProjectSeed('Save for a house', LifeArea.financial, 'savings'),
  _ProjectSeed('Read more books', LifeArea.personal, 'explore'),
  _ProjectSeed('Reconnect with old friends', LifeArea.social, 'groups'),
  _ProjectSeed('Volunteer monthly', LifeArea.philanthropic, 'volunteer_activism'),
];

const _loremWords = [
  'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing', 'elit',
  'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore', 'et',
  'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam', 'quis',
  'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi', 'aliquip', 'ex', 'ea',
];

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _loremTitle(Random random) {
  final wordCount = 3 + random.nextInt(4);
  final words = List.generate(wordCount, (_) => _loremWords[random.nextInt(_loremWords.length)]);
  return _capitalize(words.join(' '));
}

/// ~40% of wins have no description, matching how the archive card looked
/// with real hand-entered data during development.
String? _loremDescription(Random random) {
  if (random.nextDouble() < 0.4) return null;
  final wordCount = 8 + random.nextInt(12);
  final words = List.generate(wordCount, (_) => _loremWords[random.nextInt(_loremWords.length)]);
  return '${_capitalize(words.join(' '))}.';
}
