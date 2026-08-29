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

    final first = await repo.add(title: 'First step', projectId: 1, intensity: 3);
    final second = await repo.add(title: 'Second step', projectId: 1, intensity: 3);

    expect(first.number, 1);
    expect(second.number, 2);
    expect(repo.getAll().map((w) => w.title), ['Second step', 'First step']);
  });

  test('blank description is stored as null, not an empty string', () async {
    final repo = await WinRepository.create();

    final win = await repo.add(title: 'A win', description: '   ', projectId: 1, intensity: 3);

    expect(win.description, isNull);
  });

  test('data survives reloading the repository from the same storage', () async {
    final repo = await WinRepository.create();
    await repo.add(title: 'A win', description: 'Some details', projectId: 1, intensity: 4);

    final reloaded = await WinRepository.create();

    expect(reloaded.getAll(), hasLength(1));
    expect(reloaded.getAll().first.title, 'A win');
    expect(reloaded.getAll().first.description, 'Some details');
    expect(reloaded.getAll().first.intensity, 4);
  });

  test('update() changes title/description/intensity but keeps id and number', () async {
    final repo = await WinRepository.create();
    final original = await repo.add(
      title: 'Original',
      description: 'Original details',
      projectId: 1,
      intensity: 2,
    );

    final updated = await repo.update(
      id: original.id,
      title: 'Updated',
      description: '',
      projectId: 1,
      intensity: 5,
      date: original.date,
    );

    expect(updated.id, original.id);
    expect(updated.number, original.number);
    expect(updated.date, original.date);
    expect(updated.title, 'Updated');
    expect(updated.description, isNull);
    expect(updated.intensity, 5);
    expect(repo.getAll().single.title, 'Updated');
  });

  test('update() can change a win\'s date', () async {
    final repo = await WinRepository.create();
    final original = await repo.add(title: 'A win', projectId: 1, intensity: 3);
    final newDate = DateTime(2024, 1, 5);

    final updated = await repo.update(
      id: original.id,
      title: original.title,
      projectId: original.projectId,
      intensity: original.intensity,
      date: newDate,
    );

    expect(updated.date, newDate);
  });

  test('update() can reassign a win to a different project', () async {
    final repo = await WinRepository.create();
    final original = await repo.add(title: 'A win', projectId: 1, intensity: 3);

    final updated = await repo.update(
      id: original.id,
      title: original.title,
      projectId: 2,
      intensity: original.intensity,
      date: original.date,
    );

    expect(updated.projectId, 2);
    expect(repo.getAllForProject(1), isEmpty);
    expect(repo.getAllForProject(2).map((w) => w.id), [original.id]);
  });

  test('update() throws for an id that does not exist', () async {
    final repo = await WinRepository.create();

    expect(
      () => repo.update(id: 999, title: 'Nope', projectId: 1, intensity: 3, date: DateTime.now()),
      throwsStateError,
    );
  });

  test('getAllForProject() returns only that project\'s wins, oldest first', () async {
    final repo = await WinRepository.create();

    await repo.add(title: 'Project 1, win A', projectId: 1, intensity: 3);
    await repo.add(title: 'Project 2, win A', projectId: 2, intensity: 3);
    await repo.add(title: 'Project 1, win B', projectId: 1, intensity: 3);

    expect(
      repo.getAllForProject(1).map((w) => w.title),
      ['Project 1, win A', 'Project 1, win B'],
    );
    expect(repo.getAllForProject(2).map((w) => w.title), ['Project 2, win A']);
    expect(repo.getAllForProject(3), isEmpty);
  });

  test('delete() removes the win and persists across a reload', () async {
    final repo = await WinRepository.create();
    final keep = await repo.add(title: 'Keep me', projectId: 1, intensity: 3);
    final remove = await repo.add(title: 'Remove me', projectId: 1, intensity: 3);

    await repo.delete(remove.id);

    expect(repo.getAll().map((w) => w.id), [keep.id]);
    final reloaded = await WinRepository.create();
    expect(reloaded.getAll().map((w) => w.id), [keep.id]);
  });

  test('delete() for an id that does not exist is a harmless no-op', () async {
    final repo = await WinRepository.create();
    await repo.add(title: 'A win', projectId: 1, intensity: 3);

    await repo.delete(999);

    expect(repo.getAll(), hasLength(1));
  });

  test('clear() deletes every win, including from a repository reloaded afterward', () async {
    final repo = await WinRepository.create();
    await repo.add(title: 'A win', projectId: 1, intensity: 3);

    await repo.clear();

    expect(repo.getAll(), isEmpty);
    final reloaded = await WinRepository.create();
    expect(reloaded.getAll(), isEmpty);
  });
}
