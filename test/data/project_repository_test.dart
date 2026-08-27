import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:victory_stars/data/project_repository.dart';
import 'package:victory_stars/models/life_area.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty when nothing has been saved yet', () async {
    final repo = await ProjectRepository.create();

    expect(repo.getAll(), isEmpty);
  });

  test('add() persists name, area, and iconSlug', () async {
    final repo = await ProjectRepository.create();

    final project = await repo.add(name: 'Build this app', area: LifeArea.professional, iconSlug: 'rocket_launch');

    expect(project.name, 'Build this app');
    expect(project.area, LifeArea.professional);
    expect(project.iconSlug, 'rocket_launch');
  });

  test('getProjectsForArea() only returns projects in that area', () async {
    final repo = await ProjectRepository.create();

    await repo.add(name: 'Build this app', area: LifeArea.professional, iconSlug: 'rocket_launch');
    await repo.add(name: 'Find a job', area: LifeArea.professional, iconSlug: 'work');
    await repo.add(name: 'Run a 10k', area: LifeArea.physical, iconSlug: 'fitness_center');

    expect(repo.getProjectsForArea(LifeArea.professional).map((p) => p.name), ['Find a job', 'Build this app']);
    expect(repo.getProjectsForArea(LifeArea.physical).map((p) => p.name), ['Run a 10k']);
    expect(repo.getProjectsForArea(LifeArea.spiritual), isEmpty);
  });

  test('data survives reloading the repository from the same storage', () async {
    final repo = await ProjectRepository.create();
    await repo.add(name: 'Build this app', area: LifeArea.professional, iconSlug: 'rocket_launch');

    final reloaded = await ProjectRepository.create();

    expect(reloaded.getAll(), hasLength(1));
    expect(reloaded.getAll().first.name, 'Build this app');
    expect(reloaded.getAll().first.area, LifeArea.professional);
  });

  test('clear() deletes every project, including from a repository reloaded afterward', () async {
    final repo = await ProjectRepository.create();
    await repo.add(name: 'Build this app', area: LifeArea.professional, iconSlug: 'rocket_launch');

    await repo.clear();

    expect(repo.getAll(), isEmpty);
    final reloaded = await ProjectRepository.create();
    expect(reloaded.getAll(), isEmpty);
  });
}
