import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:victory_stars/data/win_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty when nothing has been saved yet', () async {
    final repo = await WinRepository.create();

    expect(repo.getAll(), isEmpty);
  });

  test('add() assigns sequential numbers and orders newest first', () async {
    final repo = await WinRepository.create();

    final first = await repo.add(title: 'First step', projectId: 1);
    final second = await repo.add(title: 'Second step', projectId: 1);

    expect(first.number, 1);
    expect(second.number, 2);
    expect(repo.getAll().map((w) => w.title), ['Second step', 'First step']);
  });

  test('blank description is stored as null, not an empty string', () async {
    final repo = await WinRepository.create();

    final win = await repo.add(title: 'A win', description: '   ', projectId: 1);

    expect(win.description, isNull);
  });

  test('data survives reloading the repository from the same storage', () async {
    final repo = await WinRepository.create();
    await repo.add(title: 'A win', description: 'Some details', projectId: 1);

    final reloaded = await WinRepository.create();

    expect(reloaded.getAll(), hasLength(1));
    expect(reloaded.getAll().first.title, 'A win');
    expect(reloaded.getAll().first.description, 'Some details');
  });

  test('update() changes title/description but keeps id, number, and date', () async {
    final repo = await WinRepository.create();
    final original = await repo.add(title: 'Original', description: 'Original details', projectId: 1);

    final updated = await repo.update(id: original.id, title: 'Updated', description: '');

    expect(updated.id, original.id);
    expect(updated.number, original.number);
    expect(updated.date, original.date);
    expect(updated.title, 'Updated');
    expect(updated.description, isNull);
    expect(repo.getAll().single.title, 'Updated');
  });

  test('update() throws for an id that does not exist', () async {
    final repo = await WinRepository.create();

    expect(() => repo.update(id: 999, title: 'Nope'), throwsStateError);
  });

  test('getAllForProject() returns only that project\'s wins, oldest first', () async {
    final repo = await WinRepository.create();

    await repo.add(title: 'Project 1, win A', projectId: 1);
    await repo.add(title: 'Project 2, win A', projectId: 2);
    await repo.add(title: 'Project 1, win B', projectId: 1);

    expect(
      repo.getAllForProject(1).map((w) => w.title),
      ['Project 1, win A', 'Project 1, win B'],
    );
    expect(repo.getAllForProject(2).map((w) => w.title), ['Project 2, win A']);
    expect(repo.getAllForProject(3), isEmpty);
  });
}
