import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:victory_stars/data/constellation_shapes_v2.dart';
import 'package:victory_stars/data/custom_constellation_repository.dart';
import 'package:victory_stars/data/legacy_constellation_migration.dart';
import 'package:victory_stars/data/project_repository.dart';
import 'package:victory_stars/models/life_area.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('backfills a project with no customConstellationId, matching its legacy icon shape', () async {
    final projectRepository = await ProjectRepository.create();
    final customConstellationRepository = await CustomConstellationRepository.create();
    await projectRepository.add(
      name: 'Build this app',
      area: LifeArea.professional,
      iconSlug: 'rocket_launch',
    );

    await backfillMissingConstellations(
      projectRepository: projectRepository,
      customConstellationRepository: customConstellationRepository,
    );

    final migrated = projectRepository.getAll().single;
    expect(migrated.customConstellationId, isNotNull);
    final shape = customConstellationRepository.getById(migrated.customConstellationId!);
    expect(shape, isNotNull);
    expect(shape!.name, 'Build this app');
    expect(shape.shape.points, constellationShapes['rocket_launch']!.points);
    expect(shape.shape.edges, constellationShapes['rocket_launch']!.edges);
  });

  test('leaves a project that already has a customConstellationId untouched', () async {
    final projectRepository = await ProjectRepository.create();
    final customConstellationRepository = await CustomConstellationRepository.create();
    final custom = await customConstellationRepository.add(
      name: 'My own shape',
      shape: constellationShapes['rocket_launch']!,
    );
    final project = await projectRepository.add(
      name: 'Build this app',
      area: LifeArea.professional,
      iconSlug: 'rocket_launch',
      customConstellationId: custom.id,
    );

    await backfillMissingConstellations(
      projectRepository: projectRepository,
      customConstellationRepository: customConstellationRepository,
    );

    expect(projectRepository.getAll().single.customConstellationId, custom.id);
    expect(customConstellationRepository.getAll(), hasLength(1));
    expect(project.customConstellationId, custom.id);
  });

  test('running it twice does not create duplicate shapes', () async {
    final projectRepository = await ProjectRepository.create();
    final customConstellationRepository = await CustomConstellationRepository.create();
    await projectRepository.add(
      name: 'Build this app',
      area: LifeArea.professional,
      iconSlug: 'rocket_launch',
    );

    await backfillMissingConstellations(
      projectRepository: projectRepository,
      customConstellationRepository: customConstellationRepository,
    );
    final idAfterFirstRun = projectRepository.getAll().single.customConstellationId;

    await backfillMissingConstellations(
      projectRepository: projectRepository,
      customConstellationRepository: customConstellationRepository,
    );

    expect(projectRepository.getAll().single.customConstellationId, idAfterFirstRun);
    expect(customConstellationRepository.getAll(), hasLength(1));
  });

  test('a project whose iconSlug has no legacy shape entry is left alone (no crash)', () async {
    final projectRepository = await ProjectRepository.create();
    final customConstellationRepository = await CustomConstellationRepository.create();
    await projectRepository.add(
      name: 'Mystery project',
      area: LifeArea.professional,
      iconSlug: 'not_a_real_slug',
    );

    await backfillMissingConstellations(
      projectRepository: projectRepository,
      customConstellationRepository: customConstellationRepository,
    );

    expect(projectRepository.getAll().single.customConstellationId, isNull);
    expect(customConstellationRepository.getAll(), isEmpty);
  });
}
