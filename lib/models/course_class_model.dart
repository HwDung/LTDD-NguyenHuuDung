import 'lecturer_model.dart';
import 'subject_model.dart';

class CourseClassModel {
  final int? id;
  final String code;
  final int subjectId;
  final String? lecturerId;
  final String? lecturerCode;
  final String? lecturerName;
  final LecturerModel? lecturer;
  final String semester;
  final int academicYear;
  final int capacity;
  final SubjectModel? subject;

  CourseClassModel({
    this.id,
    required this.code,
    required this.subjectId,
    this.lecturerId,
    this.lecturerCode,
    this.lecturerName,
    this.lecturer,
    required this.semester,
    this.academicYear = 2026,
    this.capacity = 50,
    this.subject,
  });

  String get displayLecturer {
    if (lecturerName != null && lecturerName!.trim().isNotEmpty) {
      if (lecturerCode != null && lecturerCode!.trim().isNotEmpty) {
        return '$lecturerName ($lecturerCode)';
      }
      return lecturerName!;
    }
    if (lecturer?.fullName != null && lecturer!.fullName.trim().isNotEmpty) {
      if (lecturer!.lecturerCode.trim().isNotEmpty) {
        return '${lecturer!.fullName} (${lecturer!.lecturerCode})';
      }
      return lecturer!.fullName;
    }
    if (lecturerCode != null && lecturerCode!.trim().isNotEmpty) {
      return lecturerCode!;
    }
    if (lecturerId != null && lecturerId!.trim().isNotEmpty) {
      return lecturerId!;
    }
    return 'Chưa phân công';
  }

  factory CourseClassModel.fromJson(Map<String, dynamic> json) {
    final lecturerMap = json['lecturer'] is Map
        ? Map<String, dynamic>.from(json['lecturer'])
        : null;
    final parsedLecturer = lecturerMap != null ? LecturerModel.fromJson(lecturerMap) : null;

    final pLecturerCode = parsedLecturer?.lecturerCode.isNotEmpty == true
        ? parsedLecturer!.lecturerCode
        : (json['lecturerCode']?.toString() ?? json['teacherCode']?.toString());

    final pLecturerName = parsedLecturer?.fullName.isNotEmpty == true
        ? parsedLecturer!.fullName
        : (json['lecturerName']?.toString() ?? json['teacherName']?.toString());

    final pLecturerId = json['lecturerId']?.toString() ??
        parsedLecturer?.id ??
        lecturerMap?['userId']?.toString() ??
        json['teacherId']?.toString();

    return CourseClassModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      code: json['code']?.toString() ?? '',
      subjectId: json['subjectId'] is int
          ? json['subjectId'] as int
          : int.tryParse(json['subjectId']?.toString() ?? '0') ?? 0,
      lecturerId: pLecturerId,
      lecturerCode: pLecturerCode,
      lecturerName: pLecturerName,
      lecturer: parsedLecturer,
      semester: json['semester']?.toString() ?? 'Học kỳ 1',
      academicYear: json['academicYear'] is int
          ? json['academicYear'] as int
          : int.tryParse(json['academicYear']?.toString() ?? '2026') ?? 2026,
      capacity: json['capacity'] is int
          ? json['capacity'] as int
          : int.tryParse(json['capacity']?.toString() ?? '50') ?? 50,
      subject: json['subject'] is Map ? SubjectModel.fromJson(Map<String, dynamic>.from(json['subject'])) : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'code': code,
      'subjectId': subjectId,
      'semester': semester,
      'academicYear': academicYear,
      'capacity': capacity,
    };
    if (lecturerId != null && lecturerId!.isNotEmpty) {
      map['lecturerId'] = lecturerId;
    }
    if (lecturerCode != null && lecturerCode!.isNotEmpty) {
      map['lecturerCode'] = lecturerCode;
    }
    if (lecturerName != null && lecturerName!.isNotEmpty) {
      map['lecturerName'] = lecturerName;
    }
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }
}
