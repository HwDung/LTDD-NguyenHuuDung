class SubjectModel {
  final int? id;
  final String code;
  final String name;
  final int credits;
  final String? description;
  final bool isActive;

  SubjectModel({
    this.id,
    required this.code,
    required this.name,
    this.credits = 3,
    this.description,
    this.isActive = true,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      credits: json['credits'] is int ? json['credits'] as int : int.tryParse(json['credits']?.toString() ?? '3') ?? 3,
      description: json['description']?.toString(),
      isActive: json['isActive'] == true || json['isActive']?.toString() == 'true',
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'code': code,
      'name': name,
      'credits': credits,
      'description': description ?? '',
      'isActive': isActive,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }
}
