class LecturerModel {
  final String id;
  final String lecturerCode;
  final String fullName;
  final String email;
  final String department;
  final String? phoneNumber;

  LecturerModel({
    required this.id,
    required this.lecturerCode,
    required this.fullName,
    required this.email,
    required this.department,
    this.phoneNumber,
  });

  factory LecturerModel.fromJson(Map<String, dynamic> json) {
    return LecturerModel(
      id: (json['id'] ?? json['userId'])?.toString() ?? '',
      lecturerCode: json['lecturerCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['user']?['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? json['user']?['email']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Khoa Công nghệ thông tin',
      phoneNumber: json['phoneNumber']?.toString() ?? json['user']?['phoneNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lecturerCode': lecturerCode,
      'fullName': fullName,
      'email': email,
      'department': department,
      'phoneNumber': phoneNumber,
    };
  }
}
