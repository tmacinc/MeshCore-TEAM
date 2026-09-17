// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
//
// Needs a native sqlite3 for the test runner (the app gets one from
// sqlite3_flutter_libs, which does not apply here):
//
//   flutter test test/heard_adverts_test.dart \
//     --dart-define=MBTILES_SQLITE_DLL=C:\Python314\DLLs\sqlite3.dll

import 'dart:ffi';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_team/database/database.dart';
import 'package:sqlite3/open.dart';

const _dllPath = String.fromEnvironment('MBTILES_SQLITE_DLL');

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (seed + i) & 0xFF));

void main() {
  if (_dllPath.isEmpty) {
    test('heard adverts (skipped: no DLL configured)', () {},
        skip: 'Pass --dart-define=MBTILES_SQLITE_DLL');
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    open.overrideFor(
        OperatingSystem.windows, () => DynamicLibrary.open(_dllPath));
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open(_dllPath));
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> record(
    int seed, {
    String name = 'Stranger',
    int advertType = 1,
    int advertTimestamp = 100,
  }) {
    return db.heardAdvertsDao.record(
      publicKey: _key(seed),
      name: name,
      advertType: advertType,
      lastAdvertTimestamp: advertTimestamp,
    );
  }

  test('a heard advert is listed for the user', () async {
    await record(1, name: 'Stranger');

    final pending = await db.heardAdvertsDao.watchPending().first;

    expect(pending.length, 1);
    expect(pending.single.name, 'Stranger');
  });

  test('hearing the same node again updates it instead of duplicating',
      () async {
    await record(1, name: 'Stranger');
    await record(1, name: 'Renamed', advertTimestamp: 200);

    final pending = await db.heardAdvertsDao.watchPending().first;

    expect(pending.length, 1);
    expect(pending.single.name, 'Renamed');
  });

  test('a dismissed node stays hidden until a newer advert arrives', () async {
    await record(1, advertTimestamp: 100);
    await db.heardAdvertsDao.dismiss(_key(1));

    expect(await db.heardAdvertsDao.watchPending().first, isEmpty);

    // Hearing the same advert again must not undo the dismissal...
    await record(1, advertTimestamp: 100);
    expect(await db.heardAdvertsDao.watchPending().first, isEmpty);

    // ...but a newer one means they are still around, so offer them again.
    await record(1, advertTimestamp: 200);
    expect(await db.heardAdvertsDao.watchPending().first, hasLength(1));
  });

  test('someone already in contacts is not offered', () async {
    await record(1, name: 'Stranger');
    await db.into(db.contacts).insert(ContactsCompanion.insert(
          publicKey: _key(1),
          hash: 1,
          name: const Value('Stranger'),
          lastSeen: 0,
        ));

    expect(await db.heardAdvertsDao.watchPending().first, isEmpty);
  });

  test('the list is capped so a busy mesh cannot grow it without end',
      () async {
    for (var i = 0; i < 12; i++) {
      await record(i, name: 'Node $i');
    }

    await db.heardAdvertsDao.trimTo(10);

    final all = await db.select(db.heardAdverts).get();
    expect(all.length, 10);
  });

  test('old entries are pruned by age', () async {
    await record(1);
    final future = DateTime.now()
        .add(const Duration(days: 8))
        .millisecondsSinceEpoch;

    final removed = await db.heardAdvertsDao.deleteOlderThan(future);

    expect(removed, 1);
    expect(await db.heardAdvertsDao.watchPending().first, isEmpty);
  });
}
