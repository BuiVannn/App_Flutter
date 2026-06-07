import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ptalk_core/ptalk_core.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('lưu và đọc lại bé active', () async {
    final store = ActiveChildStore();
    expect(await store.read(), isNull);

    await store.save(ActiveChild(
        childId: '1', username: 'child_1', fullName: 'Bé An'));
    final got = await store.read();

    expect(got!.childId, '1');
    expect(got.username, 'child_1');
    expect(got.fullName, 'Bé An');
  });

  test('clear xoá bé active', () async {
    final store = ActiveChildStore();
    await store.save(ActiveChild(childId: '1', username: 'u', fullName: 'n'));
    await store.clear();
    expect(await store.read(), isNull);
  });
}
