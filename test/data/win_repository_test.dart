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

    final first = await repo.add(title: 'First step');
    final second = await repo.add(title: 'Second step');

    expect(first.number, 1);
    expect(second.number, 2);
    expect(repo.getAll().map((w) => w.title), ['Second step', 'First step']);
  });

  test('blank description is stored as null, not an empty string', () async {
    final repo = await WinRepository.create();

    final win = await repo.add(title: 'A win', description: '   ');

    expect(win.description, isNull);
  });

  test('data survives reloading the repository from the same storage', () async {
    final repo = await WinRepository.create();
    await repo.add(title: 'A win', description: 'Some details');

    final reloaded = await WinRepository.create();

    expect(reloaded.getAll(), hasLength(1));
    expect(reloaded.getAll().first.title, 'A win');
    expect(reloaded.getAll().first.description, 'Some details');
  });
}
