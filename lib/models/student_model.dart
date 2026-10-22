class StudentModel {
  static const String defaultAvatarBase64 =
      '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';

  final String id;
  final String studentCode; // Ví dụ: SV000299
  final String fullName;
  final String email;
  final String faculty;
  final String major;
  final String? phoneNumber;
  final String? photoBase64; // Ảnh khuôn mặt dùng đối soát điểm danh
  final String? photoPath;

  StudentModel({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.email,
    this.faculty = 'Công nghệ thông tin',
    this.major = 'Kỹ thuật phần mềm',
    this.phoneNumber,
    this.photoBase64,
    this.photoPath,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userMap = rawUser is Map<String, dynamic> ? rawUser : null;
    final rawAvatar = (json['photoBase64'] ?? json['avatarUrl'])?.toString().trim();
    String? validPhoto = rawAvatar;
    if (validPhoto == null || validPhoto.isEmpty || validPhoto.contains('dicebear.com')) {
      validPhoto = defaultAvatarBase64;
    }

    return StudentModel(
      id: (json['id'] ?? json['userId'])?.toString() ?? '',
      studentCode: json['studentCode']?.toString() ?? '',
      fullName: (json['fullName'] ?? userMap?['fullName'])?.toString() ?? '',
      email: (json['email'] ?? userMap?['email'])?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? 'Công nghệ thông tin',
      major: json['major']?.toString() ?? 'Kỹ thuật phần mềm',
      phoneNumber: (json['phoneNumber'] ?? userMap?['phoneNumber'])?.toString(),
      photoBase64: validPhoto,
      photoPath: json['photoPath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': id,
      'studentCode': studentCode,
      'fullName': fullName,
      'email': email,
      'faculty': faculty,
      'major': major,
      'phoneNumber': phoneNumber,
      'photoBase64': photoBase64,
      'avatarUrl': photoBase64,
      'photoPath': photoPath,
    };
  }

  StudentModel copyWith({
    String? id,
    String? studentCode,
    String? fullName,
    String? email,
    String? faculty,
    String? major,
    String? phoneNumber,
    String? photoBase64,
    String? photoPath,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentCode: studentCode ?? this.studentCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoBase64: photoBase64 ?? this.photoBase64,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
