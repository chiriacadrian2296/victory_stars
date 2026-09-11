import 'constellation_presets.dart';
import 'custom_constellation_repository.dart';
import 'project_repository.dart';

/// Gives a real constellation to every [Project] that somehow doesn't have
/// one — a project that predates the in-app editor, or one the debug seed
/// tool made (it still creates projects the old way, icon slug only).
///
/// The shape comes from the ready-made library: the preset paired with that
/// project's own [Project.iconSlug] where there is one (so a project badged
/// with a rocket gets the rocket shape), otherwise a deterministic pick from
/// the catalogue, seeded by the slug itself so the same slug always lands on
/// the same shape. Projects that share a slug share one materialized copy
/// rather than each minting their own — see
/// [StarsShapeRepository.materializePreset].
///
/// This used to map each legacy slug to one of 20 real-astronomy shapes
/// (Orion, Cassiopeia, ...) kept solely as migration data. Those are gone
/// now that the library exists: a project being backfilled today gets a
/// shape someone can recognize and re-pick, instead of a fossil nothing else
/// in the app could produce.
///
/// Idempotent: skips any project that already has a
/// [Project.starsShapeId], so it's safe to call on every app launch
/// (see `main.dart`) and again right after seeding sample data (see
/// `SettingsScreen._seedSampleData`) without ever creating a duplicate.
Future<void> backfillMissingConstellations({
  required ProjectRepository projectRepository,
  required StarsShapeRepository starsShapeRepository,
}) async {
  for (final project in projectRepository.getAll()) {
    if (project.starsShapeId != null) continue;

    final materialized = await starsShapeRepository.materializePreset(
      presetForIconSlug(project.iconSlug),
    );
    await projectRepository.assignStarsShape(
      projectId: project.id,
      starsShapeId: materialized.id,
    );
  }
}
