class ClassSessionModel {
  final int? id;
  final int courseClassId;
  final int? sessionNumber;
  final DateTime? startTime;
  final DateTime? endTime;
  final String room;
  final String? topic;

  ClassSessionModel({
    this.id,
    required this.courseClassId,
    this.sessionNumber,
    this.startTime,
    this.endTime,
    required this.room,
    this.topic,
  });

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    return ClassSessionModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      courseClassId: json['courseClassId'] is int
          ? json['courseClassId'] as int
          : int.tryParse(json['courseClassId']?.toString() ?? '0') ?? 0,
      sessionNumber: json['sessionNumber'] is int
          ? json['sessionNumber'] as int
          : int.tryParse(json['sessionNumber']?.toString() ?? '1'),
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      room: json['room']?.toString() ?? '',
      topic: json['topic']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final now = DateTime.now();
    final map = <String, dynamic>{
      'courseClassId': courseClassId,
      'sessionNumber': sessionNumber ?? 1,
      'room': room,
      'topic': topic ?? 'Buổi học',
      'startTime': (startTime ?? now).toIso8601String(),
      'endTime': (endTime ?? now.add(const Duration(hours: 2))).toIso8601String(),
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }
}
