import 'package:flutter_test/flutter_test.dart';
import 'package:ptalk_core/ptalk_core.dart';

void main() {
  test('ParentProfile.fromJson', () {
    final p = ParentProfile.fromJson({
      'fullName': 'Lê Hoàng Nam',
      'phone': '0901234567',
      'email': 'namnx@ptalk.vn',
      'subscriptionTier': 'pro',
    });
    expect(p.fullName, 'Lê Hoàng Nam');
    expect(p.phone, '0901234567');
    expect(p.subscriptionTier, 'pro');
  });

  test('ChildProfile map nhãn lớp / bộ sách / quan hệ', () {
    final c = ChildProfile.fromJson({
      'id': 'abc',
      'username': 'child_x',
      'fullName': 'Lê Hoàng An',
      'grade': '4',
      'dateOfBirth': '2016-05-12',
      'hometown': 'Thanh Hoá',
      'curriculum': 'ket_noi_tri_thuc',
      'relationship': 'father',
    });
    expect(c.gradeLabel, 'Lớp 4');
    expect(c.curriculumLabel, 'Kết nối tri thức');
    expect(c.relationshipLabel, 'Bố');
  });

  test('UsageToday.fromJson với quota null = không giới hạn', () {
    final u = UsageToday.fromJson(
        {'usageToday': 12, 'quota': null, 'resetsAt': '2026-06-08T00:00:00.000Z'});
    expect(u.used, 12);
    expect(u.isUnlimited, true);
    expect(u.available, true);
  });

  test('UsageToday.fromJson thiếu field (backend chưa cập nhật) = không available', () {
    final u = UsageToday.fromJson({'fullName': 'x'}); // không có usageToday
    expect(u.available, false);
  });
}
