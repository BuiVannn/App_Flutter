String? _s(dynamic v) => v == null ? null : v.toString();

class ParentProfile {
  final String fullName;
  final String? phone;
  final String email;
  final String subscriptionTier; // basic | pro | ultra | admin
  ParentProfile({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.subscriptionTier,
  });
  factory ParentProfile.fromJson(Map<String, dynamic> j) => ParentProfile(
        fullName: _s(j['fullName']) ?? _s(j['displayName']) ?? '',
        phone: _s(j['phone']),
        email: _s(j['email']) ?? '',
        subscriptionTier: _s(j['subscriptionTier']) ?? 'basic',
      );
}

const _curriculumLabels = {
  'chan_troi_sang_tao': 'Chân trời sáng tạo',
  'canh_dieu': 'Cánh diều',
  'ket_noi_tri_thuc': 'Kết nối tri thức',
};
const _relationshipLabels = {
  'father': 'Bố',
  'mother': 'Mẹ',
  'grandparent': 'Ông/Bà',
  'guardian': 'Người giám hộ',
  'other': 'Khác',
};

class ChildProfile {
  final String id;
  final String username;
  final String fullName;
  final String? grade;
  final String? dateOfBirth;
  final String? hometown;
  final String? curriculum;
  final String? relationship;
  ChildProfile({
    required this.id,
    required this.username,
    required this.fullName,
    this.grade,
    this.dateOfBirth,
    this.hometown,
    this.curriculum,
    this.relationship,
  });
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: _s(j['id']) ?? '',
        username: _s(j['username']) ?? '',
        fullName: _s(j['fullName']) ?? '',
        grade: _s(j['grade']),
        dateOfBirth: _s(j['dateOfBirth']),
        hometown: _s(j['hometown']),
        curriculum: _s(j['curriculum']),
        relationship: _s(j['relationship']),
      );

  String get gradeLabel => (grade == null || grade!.isEmpty) ? '—' : 'Lớp $grade';
  String get curriculumLabel => _curriculumLabels[curriculum] ?? '—';
  String get relationshipLabel => _relationshipLabels[relationship] ?? '—';
}

class UsageToday {
  final int used;
  final int? quota; // null = không giới hạn
  final String? resetsAt;
  final bool available; // false = backend chưa trả field lượt dùng (Phase B chưa làm)
  UsageToday(
      {required this.used,
      required this.quota,
      this.resetsAt,
      this.available = true});
  bool get isUnlimited => quota == null;
  double get fraction =>
      (quota == null || quota == 0) ? 0 : (used / quota!).clamp(0, 1);
  factory UsageToday.fromJson(Map<String, dynamic> j) => UsageToday(
        used: (j['usageToday'] as num?)?.toInt() ?? 0,
        quota: (j['quota'] as num?)?.toInt(),
        resetsAt: _s(j['resetsAt']),
        available: j.containsKey('usageToday'),
      );
}

/// Bé đang dùng app — lưu local, đính vào phiên voice.
class ActiveChild {
  final String childId;
  final String username; // = device_id gửi CloudPTalk
  final String fullName;
  ActiveChild({required this.childId, required this.username, required this.fullName});
}
