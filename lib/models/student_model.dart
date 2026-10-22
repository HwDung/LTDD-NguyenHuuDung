class StudentModel {
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
    return StudentModel(
      id: (json['id'] ?? json['userId'])?.toString() ?? '',
      studentCode: json['studentCode']?.toString() ?? '',
      fullName: (json['fullName'] ?? userMap?['fullName'])?.toString() ?? '',
      email: (json['email'] ?? userMap?['email'])?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? 'Công nghệ thông tin',
      major: json['major']?.toString() ?? 'Kỹ thuật phần mềm',
      phoneNumber: (json['phoneNumber'] ?? userMap?['phoneNumber'])?.toString(),
      photoBase64: (json['avatarUrl'] ?? json['photoBase64'])?.toString(),
      photoPath: json['photoPath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentCode': studentCode,
      'fullName': fullName,
      'email': email,
      'faculty': faculty,
      'major': major,
      'phoneNumber': phoneNumber,
      'photoBase64': photoBase64,
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
