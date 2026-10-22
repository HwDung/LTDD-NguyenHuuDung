class EnrollmentModel {
  final int? id;
  final int courseClassId;
  final String studentId;
  final DateTime? enrolledAtUtc;
  final int status; // 0: Đang học, 1: Đã rút, 2: Hoàn thành
  final String? studentName;
  final String? courseClassName;

  EnrollmentModel({
    this.id,
    required this.courseClassId,
    required this.studentId,
    this.enrolledAtUtc,
    this.status = 0,
    this.studentName,
    this.courseClassName,
  });

  String get statusText {
    switch (status) {
      case 0:
        return 'Đang học';
      case 1:
        return 'Đã rút môn';
      case 2:
        return 'Hoàn thành';
      default:
        return 'Chưa xác định';
    }
  }

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      courseClassId: json['courseClassId'] is int
          ? json['courseClassId'] as int
          : int.tryParse(json['courseClassId']?.toString() ?? '0') ?? 0,
      studentId: json['studentId']?.toString() ?? '',
      enrolledAtUtc: json['enrolledAtUtc'] != null ? DateTime.tryParse(json['enrolledAtUtc'].toString()) : null,
      status: json['status'] is int ? json['status'] as int : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      studentName: json['student']?['user']?['fullName'] ?? json['student']?['studentCode'] ?? json['studentId']?.toString(),
      courseClassName: json['courseClass']?['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'courseClassId': courseClassId,
      'studentId': studentId,
      'status': status,
      'enrolledAtUtc': (enrolledAtUtc ?? DateTime.now().toUtc()).toIso8601String(),
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }
}
