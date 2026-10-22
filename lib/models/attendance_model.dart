class AttendanceModel {
  final int? id;
  final int classSessionId;
  final String studentId; // SQL Server uniqueidentifier (GUID)
  final int status; // 0: Có mặt (Present), 1: Vắng mặt (Absent), 2: Đi muộn (Late), 3: Có phép (Excused)
  final bool isFaceVerified;
  final String? capturedFaceUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? checkedInAtUtc;
  final String? deviceInfo;
  final String? note;
  final String? studentName;

  AttendanceModel({
    this.id,
    required this.classSessionId,
    required this.studentId,
    required this.status,
    this.isFaceVerified = false,
    this.capturedFaceUrl,
    this.latitude,
    this.longitude,
    DateTime? checkedInAtUtc,
    DateTime? markedAtUtc,
    this.deviceInfo,
    this.note,
    this.studentName,
  }) : checkedInAtUtc = checkedInAtUtc ?? markedAtUtc;

  // Thuộc tính tương thích ngược
  DateTime? get markedAtUtc => checkedInAtUtc;

  String get statusText {
    switch (status) {
      case 0:
        return 'Có mặt';
      case 1:
        return 'Vắng mặt';
      case 2:
        return 'Đi muộn';
      case 3:
        return 'Có phép';
      default:
        return 'Chưa điểm danh';
    }
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // 1. ClassSessionId
    final rawSessionId = json['classSessionId'] ?? json['ClassSessionId'] ?? json['sessionId'] ?? json['SessionId'];
    final parsedSessionId = rawSessionId is int ? rawSessionId : (int.tryParse(rawSessionId?.toString() ?? '0') ?? 0);

    // 2. StudentId (GUID)
    final rawStudentId = (json['studentId'] ?? json['StudentId'] ?? json['userId'] ?? json['UserId'] ?? '').toString();

    // 3. Status (0: Có mặt, 1: Vắng mặt, 2: Đi muộn, 3: Có phép)
    final rawStatus = json['status'] ?? json['Status'];
    int parsedStatus = 1;
    if (rawStatus is int) {
      parsedStatus = rawStatus;
    } else if (rawStatus != null) {
      parsedStatus = int.tryParse(rawStatus.toString()) ?? (json['isPresent'] == true ? 0 : 1);
    } else if (json['isPresent'] == true) {
      parsedStatus = 0;
    }

    // 4. IsFaceVerified
    final faceOk = json['isFaceVerified'] == true ||
        json['IsFaceVerified'] == true ||
        json['faceMatched'] == true ||
        parsedStatus == 0;

    // 5. CapturedFaceUrl
    final faceUrl = (json['capturedFaceUrl'] ??
            json['CapturedFaceUrl'] ??
            json['capturedFaceBase64'] ??
            json['capturedFaceImage'])
        ?.toString();

    // 6. Coordinates (Latitude & Longitude)
    final rawLat = json['latitude'] ?? json['Latitude'];
    final rawLon = json['longitude'] ?? json['Longitude'];
    final lat = rawLat is num ? rawLat.toDouble() : double.tryParse(rawLat?.toString() ?? '');
    final lon = rawLon is num ? rawLon.toDouble() : double.tryParse(rawLon?.toString() ?? '');

    // 7. CheckedInAtUtc
    final rawTime = json['checkedInAtUtc'] ??
        json['CheckedInAtUtc'] ??
        json['markedAtUtc'] ??
        json['MarkedAtUtc'] ??
        json['markedAt'];
    final parsedTime = rawTime != null ? DateTime.tryParse(rawTime.toString()) : null;

    // 8. DeviceInfo & Note
    final devInfo = (json['deviceInfo'] ?? json['DeviceInfo'])?.toString();
    final noteStr = (json['note'] ?? json['Note'])?.toString();

    // 9. StudentName
    final nameStr = json['studentName']?.toString() ??
        json['student']?['user']?['fullName']?.toString() ??
        json['student']?['fullName']?.toString() ??
        json['student']?['studentCode']?.toString() ??
        json['studentCode']?.toString();

    // 10. Id
    final rawId = json['id'] ?? json['Id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    return AttendanceModel(
      id: parsedId,
      classSessionId: parsedSessionId,
      studentId: rawStudentId,
      status: parsedStatus,
      isFaceVerified: faceOk,
      capturedFaceUrl: faceUrl,
      latitude: lat,
      longitude: lon,
      checkedInAtUtc: parsedTime,
      deviceInfo: devInfo,
      note: noteStr,
      studentName: nameStr,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final nowIso = (checkedInAtUtc ?? DateTime.now().toUtc()).toIso8601String();
    final map = <String, dynamic>{
      // Chuẩn camelCase
      'classSessionId': classSessionId,
      'studentId': studentId,
      'status': status,
      'isFaceVerified': isFaceVerified,
      'capturedFaceUrl': capturedFaceUrl ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'checkedInAtUtc': nowIso,
      'deviceInfo': deviceInfo ?? 'Mobile Flutter App',
      'note': note ?? 'Điểm danh QR + Khuôn mặt thành công',

      // Chuẩn PascalCase (Đúng 100% theo bảng AttendanceRecords SQL Server)
      'ClassSessionId': classSessionId,
      'StudentId': studentId,
      'Status': status,
      'IsFaceVerified': isFaceVerified,
      'CapturedFaceUrl': capturedFaceUrl ?? '',
      'Latitude': latitude,
      'Longitude': longitude,
      'CheckedInAtUtc': nowIso,
      'DeviceInfo': deviceInfo ?? 'Mobile Flutter App',
      'Note': note ?? 'Điểm danh QR + Khuôn mặt thành công',

      // Tương thích ngược cho các endpoint khác
      'markedAtUtc': nowIso,
    };
    if (includeId && id != null) {
      map['id'] = id;
      map['Id'] = id;
    }
    return map;
  }

  AttendanceModel copyWith({
    int? id,
    int? classSessionId,
    String? studentId,
    int? status,
    bool? isFaceVerified,
    String? capturedFaceUrl,
    double? latitude,
    double? longitude,
    DateTime? checkedInAtUtc,
    String? deviceInfo,
    String? note,
    String? studentName,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      classSessionId: classSessionId ?? this.classSessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      capturedFaceUrl: capturedFaceUrl ?? this.capturedFaceUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      checkedInAtUtc: checkedInAtUtc ?? this.checkedInAtUtc,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      note: note ?? this.note,
      studentName: studentName ?? this.studentName,
    );
  }
}
