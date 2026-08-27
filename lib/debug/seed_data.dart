import '../data/project_repository.dart';
import '../data/win_repository.dart';
import '../models/life_area.dart';

/// How many wins each seed project gains every time [seedSampleData] runs.
const winsPerSeedTap = 12;

/// Backdates seeded wins so the dashboard has something to show: day
/// offsets from today (0 = today), hand-chosen — not random — to exercise
/// specific things at a glance once seeded:
/// - 0..5: a live 6-day current streak (today included).
/// - 6..7: a gap, so the streak visibly breaks in the calendar.
/// - 8..10: an older, separate 3-day streak (shorter than the current one,
///   so "longest streak" still correctly reports 6).
/// - 14 (x5) and 20/25/29: a very busy day and a few sparse single days, to
///   cover the heatmap's low/medium/high brightness tiers.
/// Every seed tap re-applies this same pattern from today, so repeat taps
/// pile more wins onto the same days (brighter, not further back) — which
/// suits the dashboard's calendar now only showing the current month.
const _dayOffsets = [
  0, 0, 0, 1, 1, 2, 3, 4, 5, //
  8, 8, 9, 10, //
  14, 14, 14, 14, 14, //
  20, 25, 29,
];

/// Debug helper: grows a fixed set of projects — with plausible, hand-written
/// wins, not random word salad — spread across most areas, so the
/// Sky/constellation UI can be explored without hand-entering data.
///
/// Idempotent on the *project* level — re-running finds each project by name
/// and reuses it instead of creating a duplicate. Which wins get added is
/// fully deterministic: each project's phrase list is cycled through in a
/// fixed order based on how many wins it already has, so running this
/// repeatedly (or on a fresh install) always produces the same sequence of
/// content — nothing here is randomized. "Build this app" has a shorter
/// phrase list that repeats sooner, so it's the one that reaches its
/// constellation's slot capacity (~160) after enough taps and exercises the
/// overflow fallback. Spiritual is left with no seed project, to exercise
/// that area's empty state.
Future<void> seedSampleData({
  required WinRepository winRepository,
  required ProjectRepository projectRepository,
}) async {
  assert(
    _specs.every((spec) => spec.iconSlug != spec.area.iconSlug),
    'A seed project is using its own area\'s reserved icon.',
  );

  final existingByName = {
    for (final project in projectRepository.getAll()) project.name: project,
  };

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var globalIndex = 0;

  for (final spec in _specs) {
    var project = existingByName[spec.name];
    project ??= await projectRepository.add(name: spec.name, area: spec.area, iconSlug: spec.iconSlug);

    final startingCount = winRepository.getAllForProject(project.id).length;

    for (var i = 0; i < winsPerSeedTap; i++) {
      final position = startingCount + i;
      final phrase = spec.wins[position % spec.wins.length];
      final dayOffset = _dayOffsets[globalIndex % _dayOffsets.length];
      final hour = 8 + (globalIndex * 3) % 14;
      final minute = (globalIndex * 17) % 60;
      final date = today.subtract(Duration(days: dayOffset)).add(Duration(hours: hour, minutes: minute));
      globalIndex++;

      await winRepository.add(
        title: phrase.title,
        description: phrase.description,
        projectId: project.id,
        intensity: 1 + position % 5,
        date: date,
      );
      // Win ids are millisecondsSinceEpoch; a tight loop without this could
      // mint duplicate ids, which every id-based lookup in the app assumes
      // can't happen.
      await Future.delayed(const Duration(milliseconds: 2));
    }
  }
}

class _WinSeed {
  const _WinSeed(this.title, [this.description]);
  final String title;
  final String? description;
}

class _ProjectSeed {
  const _ProjectSeed(this.name, this.area, this.iconSlug, this.wins);
  final String name;
  final LifeArea area;
  final String iconSlug;
  final List<_WinSeed> wins;
}

const _specs = [
  _ProjectSeed('Run a 10k', LifeArea.physical, 'sports_gymnastics', [
    _WinSeed(
      "Went for a run even though I really didn't want to",
      'It was raining and I almost bailed, but I laced up anyway.',
    ),
    _WinSeed('Finished my first 5k without stopping'),
    _WinSeed(
      'Got up for a 6am run three days in a row',
      'My legs were sore but I did it anyway.',
    ),
    _WinSeed('Ran through a cramp instead of giving up'),
    _WinSeed('Signed up for the 10k race', "Terrified, but I did it."),
    _WinSeed('Ran my personal best pace', 'Two minutes faster than last month.'),
    _WinSeed('Pushed through the last mile when I wanted to walk'),
    _WinSeed(
      'Went for a run after a really bad day at work',
      'It helped more than I expected.',
    ),
    _WinSeed("Did a hill sprint session I'd been avoiding for weeks"),
    _WinSeed('Ran in the cold without complaining (much)'),
    _WinSeed(
      'Recovered from a minor injury and got back out there',
      'Took it slow but I showed up.',
    ),
    _WinSeed("Beat last week's distance"),
  ]),
  _ProjectSeed('Learn to swim', LifeArea.physical, 'pool', [
    _WinSeed('Put my face in the water without panicking'),
    _WinSeed('Swam a full lap without stopping to catch my breath'),
    _WinSeed(
      'Went to the pool alone for the first time',
      'Nobody to hide behind, just me and the water.',
    ),
    _WinSeed('Tried the deep end', 'Heart was racing but I did it.'),
    _WinSeed('Practiced breathing technique for 20 minutes straight'),
    _WinSeed('Swam two laps without needing to stop'),
  ]),
  _ProjectSeed('Daily meditation', LifeArea.psychological, 'spa', [
    _WinSeed('Sat with an uncomfortable feeling instead of scrolling my phone'),
    _WinSeed(
      "Meditated for 10 minutes even though my mind wouldn't quiet down",
      'It still counts.',
    ),
    _WinSeed('Noticed a spiral starting and caught it early'),
    _WinSeed(
      'Did a full week of morning meditation',
      "First time I've kept a streak this long.",
    ),
    _WinSeed(
      'Sat through a panic feeling without running from it',
      'Breathed through it instead.',
    ),
    _WinSeed("Journaled honestly about something I'd been avoiding"),
    _WinSeed('Meditated after a fight instead of stewing', 'Helped me respond instead of react.'),
    _WinSeed('Noticed my thoughts without judging them, for once'),
    _WinSeed("Took a mental health day and didn't feel guilty"),
    _WinSeed('Practiced sitting in silence for 15 minutes', 'Was hard, did it anyway.'),
    _WinSeed("Talked myself down from a spiral using what I've learned"),
    _WinSeed('Meditated on a day I really did not feel like it', 'Showed up anyway.'),
  ]),
  _ProjectSeed('Build this app', LifeArea.professional, 'rocket_launch', [
    _WinSeed('Got the data model working after hours of debugging'),
    _WinSeed('Shipped the first working version', "Rough around the edges but it runs."),
    _WinSeed('Fixed a bug that had been driving me crazy for two days'),
    _WinSeed("Refactored the messy code from last week"),
    _WinSeed('Wrote tests instead of skipping them'),
    _WinSeed(
      "Figured out the animation that wasn't working",
      'Took way longer than it should have.',
    ),
    _WinSeed('Got the build running on the emulator after a frustrating setup'),
    _WinSeed('Pushed through a wall of compiler errors'),
    _WinSeed("Redesigned a screen that wasn't working visually"),
    _WinSeed(
      'Debugged a race condition that only happened sometimes',
      'Finally reproduced it.',
    ),
    _WinSeed('Kept going after a build failed three times in a row'),
    _WinSeed('Wrote documentation instead of putting it off'),
  ]),
  _ProjectSeed('Find a new job', LifeArea.professional, 'business_center', [
    _WinSeed('Sent out an application even though I felt unqualified'),
    _WinSeed('Made it through a nerve-wracking interview'),
    _WinSeed('Followed up after weeks of silence'),
    _WinSeed('Rewrote my resume instead of avoiding it'),
    _WinSeed('Asked for feedback after a rejection', 'Stung, but I learned something.'),
  ]),
  _ProjectSeed('Save for a house', LifeArea.financial, 'real_estate_agent', [
    _WinSeed('Skipped an impulse purchase and put the money aside instead'),
    _WinSeed('Made it through the month under budget'),
    _WinSeed('Had an honest look at my spending', 'Uncomfortable but necessary.'),
    _WinSeed('Said no to a night out to protect my savings'),
    _WinSeed("Hit a savings milestone I'd been working toward"),
    _WinSeed("Cut a subscription I wasn't using"),
  ]),
  _ProjectSeed('Read more books', LifeArea.personal, 'explore', [
    _WinSeed("Finished a book I'd been putting down for months"),
    _WinSeed('Read instead of scrolling before bed'),
    _WinSeed('Started a book that intimidated me'),
    _WinSeed('Finished a chapter instead of stopping mid-way'),
  ]),
  _ProjectSeed('Reconnect with old friends', LifeArea.social, 'connect_without_contact', [
    _WinSeed("Reached out to a friend I hadn't spoken to in years"),
    _WinSeed('Made the first move to patch things up', 'Awkward at first, worth it.'),
    _WinSeed('Showed up to a get-together I almost skipped'),
    _WinSeed('Called instead of just texting'),
    _WinSeed('Said something honest instead of staying quiet'),
    _WinSeed(
      'Reconnected with someone after a long silence',
      "Neither of us apologized, we just moved on.",
    ),
    _WinSeed('Made plans instead of waiting for someone else to'),
  ]),
  _ProjectSeed('Volunteer monthly', LifeArea.philanthropic, 'campaign', [
    _WinSeed('Showed up to volunteer even though I was exhausted'),
    _WinSeed('Organized a small donation drive'),
    _WinSeed('Spent a Saturday helping instead of resting', 'Tired, but glad I did it.'),
    _WinSeed('Gave up a weekend to help a neighbor move'),
    _WinSeed("Donated instead of buying something I didn't need"),
  ]),
];
