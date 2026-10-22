import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenhuudung/models/attendance_model.dart';
import 'package:nguyenhuudung/models/course_class_model.dart';
import 'package:nguyenhuudung/models/lecturer_model.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';
import 'package:nguyenhuudung/services/face_detector_service.dart';
import 'package:nguyenhuudung/services/student_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final Map<String, dynamic> memoryStorage = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        if (call.method == 'read') {
          return memoryStorage[call.arguments['key']];
        }
        if (call.method == 'write') {
          memoryStorage[call.arguments['key']] = call.arguments['value'];
          return null;
        }
        return null;
      },
    );
  });

  group('CourseClassModel & Lecturer mapping tests', () {
    test('Correctly parses API response with lecturer object & UUID', () {
      final apiJson = {
        'id': 10,
        'code': 'PRN231_01',
        'subjectId': 1,
        'lecturerId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'semester': 'Học kỳ 1 - 2026',
        'academicYear': 2026,
        'capacity': 50,
        'lecturer': {
          'userId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
          'lecturerCode': 'GV001',
          'department': 'Khoa Công nghệ thông tin',
          'user': {
            'fullName': 'ThS. Trần Văn Hùng',
            'email': 'hungtv@university.edu.vn',
          },
        },
      };

      final courseClass = CourseClassModel.fromJson(apiJson);

      expect(courseClass.id, 10);
      expect(courseClass.code, 'PRN231_01');
      expect(courseClass.lecturerId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(courseClass.lecturerCode, 'GV001');
      expect(courseClass.lecturerName, 'ThS. Trần Văn Hùng');
      expect(courseClass.displayLecturer, 'ThS. Trần Văn Hùng (GV001)');
      expect(courseClass.lecturer, isNotNull);
      expect(courseClass.lecturer!.lecturerCode, 'GV001');
    });

    test('LecturerModel parses userId as id', () {
      final lecturerJson = {
        'userId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'lecturerCode': 'GV001',
        'department': 'Khoa CNTT',
        'user': {
          'fullName': 'ThS. Trần Văn Hùng',
          'email': 'hungtv@university.edu.vn',
        },
      };

      final lecturer = LecturerModel.fromJson(lecturerJson);
      expect(lecturer.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(lecturer.lecturerCode, 'GV001');
      expect(lecturer.fullName, 'ThS. Trần Văn Hùng');
    });

    test('ClassStudentService attendanceChangeNotifier increments on record', () async {
      int notifyCount = 0;
      ClassStudentService.attendanceChangeNotifier.addListener(() {
        notifyCount++;
      });

      final service = ClassStudentService();
      // 1. Lecturer opens first (all absent)
      final initialList = await service.getSessionAttendance('test_session_1', 'PRN231');
      final initDung = initialList.firstWhere((a) => a.studentCode == 'SV000299');
      expect(initDung.isPresent, isFalse);

      // 2. Student records attendance
      await service.recordStudentAttendance(
        sessionId: 'test_session_1',
        classCode: 'PRN231',
        studentCode: 'SV000299',
        studentName: 'Nguyễn Hữu Dũng',
        faceMatchScore: 96.5,
        gpsCoordinates: '10.823099, 106.629664',
      );

      expect(notifyCount, greaterThan(0));

      // 3. Lecturer refreshes
      final attendanceList = await service.getSessionAttendance('test_session_1', 'PRN231');
      final dungRecord = attendanceList.firstWhere((a) => a.studentCode == 'SV000299');
      expect(dungRecord.isPresent, isTrue);
      expect(dungRecord.status, 0);
      expect(dungRecord.gpsCoordinates, contains('10.823099'));

      // 4. Simulate app restart (inMemoryMap cleared, re-read from storage)
      ClassStudentService.clearInMemoryCache();
      final freshList = await service.getSessionAttendance('test_session_1', 'PRN231');
      final freshDung = freshList.firstWhere((a) => a.studentCode == 'SV000299');
      expect(freshDung.isPresent, isTrue);
      expect(freshDung.status, 0);
    });

    test('StudentService ensures student photoBase64 is present and updatable', () async {
      final studentService = StudentService();
      final students = await studentService.getStudents();
      expect(students.isNotEmpty, isTrue);
      for (final s in students) {
        expect(s.photoBase64, isNotNull);
        expect(s.photoBase64!.isNotEmpty, isTrue);
      }

      const newPhoto = 'base64_test_photo_sample';
      await studentService.updateStudentPhoto('SV000299', newPhoto);
      final dung = await studentService.findByCode('SV000299');
      expect(dung, isNotNull);
      expect(dung!.photoBase64, newPhoto);
    });

    test('QR code payload validation test', () {
      bool isValidAttendanceQr(String raw) {
        try {
          String clean = raw.trim();
          if (clean.startsWith('ATTENDANCE_QR:')) {
            clean = clean.substring('ATTENDANCE_QR:'.length).trim();
          }
          final decoded = jsonDecode(clean);
          return decoded is Map && decoded['type'] == 'attendance_qr' && (decoded['classCode']?.toString().isNotEmpty ?? false);
        } catch (_) {
          return false;
        }
      }

      // Random barcode or text should fail
      expect(isValidAttendanceQr('1234567890'), isFalse);
      expect(isValidAttendanceQr('https://example.com'), isFalse);
      expect(isValidAttendanceQr('{"foo": "bar"}'), isFalse);

      // Valid attendance QR should succeed
      final validPayload = jsonEncode({
        'type': 'attendance_qr',
        'sessionId': '1',
        'classCode': 'PRN231',
        'sessionTitle': 'Buổi học 1',
        'timestamp': 123456789,
      });
      expect(isValidAttendanceQr(validPayload), isTrue);
      expect(isValidAttendanceQr('ATTENDANCE_QR:$validPayload'), isTrue);
    });

    test('FaceDetectorService handles non-existent file gracefully', () async {
      final detector = FaceDetectorService();
      final result = await detector.verifyFaceFromPath(imagePath: 'non_existent_file.jpg');
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Không tìm thấy'));
      detector.dispose();
    });

    test('FaceDetectorService rejects mismatching faces (< 80%)', () async {
      final detector = FaceDetectorService();
      final result = await detector.compareTwoFaces(
        selfiePath: 'dummy.jpg',
        referencePhotoBase64: 'base64_photo_data',
        forceMismatchTest: true,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isMatched, isFalse);
      expect(result.matchScore, lessThan(80.0));
      expect(result.message, contains('Gương mặt không khớp'));
      detector.dispose();
    });

    test('ClassStudentService isStudentPresentInClass and getClassAttendanceSummary update correctly', () async {
      final service = ClassStudentService();
      final studentCode = 'SV000299';
      final classCode = 'PRN231';

      // Record attendance
      await service.recordStudentAttendance(
        sessionId: 'session_check_1',
        classCode: classCode,
        studentCode: studentCode,
        studentName: 'Nguyễn Hữu Dũng',
        faceMatchScore: 95.8,
        gpsCoordinates: '10.823099, 106.629664',
      );

      final isPresent = await service.isStudentPresentInClass(classCode, studentCode);
      expect(isPresent, isTrue);

      // Verify that attendance is isolated and NOT falsely present in other classes
      final isPresentOtherClass = await service.isStudentPresentInClass('COMP101_01', studentCode);
      expect(isPresentOtherClass, isFalse);

      final summary = await service.getClassAttendanceSummary(classCode, sessionId: 'session_check_1');
      expect(summary['present'], greaterThanOrEqualTo(1));
    });

    test('SessionAttendanceDetail correctly determines isPresent and status', () {
      final jsonPresent = {
        'studentCode': 'SV000299',
        'studentName': 'Nguyễn Hữu Dũng',
        'status': 0, // Có mặt
      };
      final detailPresent = SessionAttendanceDetail.fromJson(jsonPresent);
      expect(detailPresent.isPresent, isTrue);
      expect(detailPresent.statusText, 'Có mặt');

      final jsonAbsent = {
        'studentCode': 'SV000300',
        'studentName': 'Trần Thị B',
        'status': 1, // Vắng
      };
      final detailAbsent = SessionAttendanceDetail.fromJson(jsonAbsent);
      expect(detailAbsent.isPresent, isFalse);
      expect(detailAbsent.statusText, 'Vắng mặt');

      // Status 2: Đi muộn (Late)
      final jsonLate = {
        'studentCode': 'SV000299',
        'studentName': 'Nguyễn Hữu Dũng',
        'status': 2,
      };
      final detailLate = SessionAttendanceDetail.fromJson(jsonLate);
      expect(detailLate.statusText, 'Đi muộn');

      // Status 3: Có phép (Excused)
      final jsonExcused = {
        'studentCode': 'SV000299',
        'studentName': 'Nguyễn Hữu Dũng',
        'status': 3,
      };
      final detailExcused = SessionAttendanceDetail.fromJson(jsonExcused);
      expect(detailExcused.statusText, 'Có phép');
    });

    test('AttendanceModel strictly adheres to SQL Server AttendanceRecords schema', () {
      final sqlServerRecord = {
        'Id': 42,
        'ClassSessionId': 10,
        'StudentId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'Status': 0,
        'IsFaceVerified': true,
        'CapturedFaceUrl': 'data:image/jpeg;base64,sample_face_data',
        'Latitude': 10.823099,
        'Longitude': 106.629664,
        'CheckedInAtUtc': '2026-10-22T08:30:00.000Z',
        'DeviceInfo': 'Mobile Flutter App',
        'Note': 'Điểm danh QR + Khuôn mặt thành công',
      };

      final model = AttendanceModel.fromJson(sqlServerRecord);
      expect(model.id, 42);
      expect(model.classSessionId, 10);
      expect(model.studentId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(model.status, 0);
      expect(model.statusText, 'Có mặt');
      expect(model.isFaceVerified, isTrue);
      expect(model.capturedFaceUrl, 'data:image/jpeg;base64,sample_face_data');
      expect(model.latitude, 10.823099);
      expect(model.longitude, 106.629664);
      expect(model.deviceInfo, 'Mobile Flutter App');
      expect(model.note, 'Điểm danh QR + Khuôn mặt thành công');

      // Test toJson() emits both PascalCase and camelCase for backend
      final jsonOut = model.toJson();
      expect(jsonOut['ClassSessionId'], 10);
      expect(jsonOut['StudentId'], '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(jsonOut['Status'], 0);
      expect(jsonOut['IsFaceVerified'], isTrue);
      expect(jsonOut['CapturedFaceUrl'], 'data:image/jpeg;base64,sample_face_data');
      expect(jsonOut['Latitude'], 10.823099);
      expect(jsonOut['Longitude'], 106.629664);
      expect(jsonOut['DeviceInfo'], 'Mobile Flutter App');
      expect(jsonOut['Note'], 'Điểm danh QR + Khuôn mặt thành công');

      expect(jsonOut['classSessionId'], 10);
      expect(jsonOut['studentId'], '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(jsonOut['status'], 0);
    });

    test('StudentService.toGuid guarantees valid SQL Server uniqueidentifier UUID', () {
      final guidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

      final guid299 = StudentService.toGuid('SV000299');
      expect(guidRegex.hasMatch(guid299), isTrue);
      expect(guid299, 'e2360a44-9dcd-4239-adfd-08df2fafa03f');

      final guid300 = StudentService.toGuid('SV000300');
      expect(guidRegex.hasMatch(guid300), isTrue);

      final guidRandom = StudentService.toGuid('SV999999');
      expect(guidRegex.hasMatch(guidRandom), isTrue);

      // Existing GUID string should pass through unchanged
      const sampleGuid = 'c2990000-0000-0000-0000-000000000299';
      expect(StudentService.toGuid(sampleGuid), sampleGuid);
    });
  });
}
