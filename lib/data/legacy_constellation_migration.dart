import 'constellation_shapes_v2.dart';
import 'custom_constellation_repository.dart';
import 'project_repository.dart';

/// Backfills every [Project] that predates the hand-drawn constellation
/// editor — or was created by the debug seed tool, which still creates
/// projects the old way — with a real [CustomConstellation], generated from
/// the fixed shape [Project.iconSlug] used to fall back to. Preserves
/// exactly what that project's constellation already looked like (same
/// points/edges, so already-lit stars don't shift), just re-homing it into
/// the same system every hand-drawn shape lives in.
///
/// Idempotent: skips any project that already has a [Project.customConstellationId],
/// so it's safe to call on every app launch (see `main.dart`) and again
/// right after seeding sample data (see `SettingsScreen._seedSampleData`)
/// without ever creating a duplicate.
Future<void> backfillMissingConstellations({
  required ProjectRepository projectRepository,
  required CustomConstellationRepository customConstellationRepository,
}) async {
  for (final project in projectRepository.getAll()) {
    if (project.customConstellationId != null) continue;
    final legacyShape = constellationShapes[project.iconSlug];
    if (legacyShape == null) continue;

    // CustomConstellation ids are millisecondsSinceEpoch — back-to-back
    // adds in this loop could otherwise mint the same id for two different
    // projects' migrated shapes, and getById() would then resolve to
    // whichever one happens to come first (see star_repository_test.dart's
    // own note on the same underlying issue).
    await Future<void>.delayed(const Duration(milliseconds: 2));

    final migrated = await customConstellationRepository.add(
      name: project.name,
      shape: legacyShape,
    );
    await projectRepository.assignCustomConstellation(
      projectId: project.id,
      customConstellationId: migrated.id,
    );
  }
}
