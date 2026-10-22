class ApiConstants {
  // Auth
  static const String register = '/auth/register';
  static const String verifyRegister = '/auth/register/verify';

  static const String login = '/auth/login';
  static const String verifyLogin = '/auth/login/verify';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Academic / CRUD endpoints
  static const String subjects = '/subjects';
  static const String courseClasses = '/course-classes';
  static const String enrollments = '/enrollments';
  static const String attendance = '/attendance';

  static String subjectById(dynamic id) => '/subjects/$id';

  static String courseClassById(dynamic id) => '/course-classes/$id';

  static String sessionsByCourseClass(dynamic courseClassId) =>
      '/course-classes/$courseClassId/sessions';

  static String sessionById(dynamic id) => '/sessions/$id';

  static String attendanceBySession(dynamic sessionId) =>
      '/sessions/$sessionId/attendance';

  static String enrollmentById(dynamic id) => '/enrollments/$id';

  static String attendanceById(dynamic id) => '/attendance/$id';
}
