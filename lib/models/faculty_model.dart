class MajorModel {
  final int id;
  final String code;
  final String name;
  final int facultyId;
  final String? description;

  MajorModel({
    required this.id,
    required this.code,
    required this.name,
    required this.facultyId,
    this.description,
  });

  factory MajorModel.fromJson(Map<String, dynamic> json) {
    return MajorModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      facultyId: json['facultyId'] is int
          ? json['facultyId'] as int
          : int.tryParse(json['facultyId']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'facultyId': facultyId,
      'description': description,
    };
  }
}

class FacultyModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final List<MajorModel> majors;

  FacultyModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.majors = const [],
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    List<MajorModel> majorsList = [];
    if (json['majors'] is List) {
      majorsList = (json['majors'] as List)
          .map((m) => MajorModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return FacultyModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      majors: majorsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'majors': majors.map((m) => m.toJson()).toList(),
    };
  }
}
