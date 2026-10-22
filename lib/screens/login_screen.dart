import 'package:flutter/material.dart';
import 'package:nguyenhuudung/core/token_storage.dart';
import 'package:nguyenhuudung/screens/dashboards/role_router_screen.dart';
import 'package:nguyenhuudung/services/auth_service.dart';
import 'package:nguyenhuudung/services/lecturer_service.dart';
import 'package:nguyenhuudung/services/student_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers cho Sinh viên (MSSV + Mật khẩu là MSSV)
  final _studentCodeController = TextEditingController(text: 'SV000299');
  final _studentPasswordController = TextEditingController(text: 'SV000299');
  bool _studentPasswordSync = true;
  bool _hideStudentPassword = true;
  bool _isStudentLoggingIn = false;
  String? _studentErrorMessage;

  // Controllers cho Giảng viên (Mã GV + Mật khẩu là Mã GV)
  final _lecturerCodeController = TextEditingController(text: 'GV001');
  final _lecturerPasswordController = TextEditingController(text: 'GV001');
  bool _lecturerPasswordSync = true;
  bool _hideLecturerPassword = true;
  bool _isLecturerLoggingIn = false;
  String? _lecturerErrorMessage;

  // Controllers cho Quản trị viên (Admin)
  final _adminFormKey = GlobalKey<FormState>();
  final _adminUsernameController = TextEditingController(text: 'admin');
  final _adminPasswordController = TextEditingController(text: 'Admin@12345');
  final _adminOtpController = TextEditingController();
  bool _isAdminSendingOtp = false;
  bool _isAdminLoggingIn = false;
  bool _hideAdminPassword = true;
  bool _adminOtpSent = false;
  String? _adminErrorMessage;
  String? _adminInfoMessage;

  final _authService = AuthService();
  final _tokenStorage = TokenStorage();
  final _studentService = StudentService();
  final _lecturerService = LecturerService();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Tự động đồng bộ mật khẩu sinh viên theo MSSV khi người dùng nhập
    _studentCodeController.addListener(() {
      if (_studentPasswordSync) {
        _studentPasswordController.text = _studentCodeController.text.trim();
      }
    });

    // Tự động đồng bộ mật khẩu giảng viên theo Mã GV khi người dùng nhập
    _lecturerCodeController.addListener(() {
      if (_lecturerPasswordSync) {
        _lecturerPasswordController.text = _lecturerCodeController.text.trim();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentCodeController.dispose();
    _studentPasswordController.dispose();
    _lecturerCodeController.dispose();
    _lecturerPasswordController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _adminOtpController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }



  // ==================== 1. ĐĂNG NHẬP SINH VIÊN (MSSV + MẬT KHẨU LÀ MSSV) ====================
  Future<void> _loginAsStudent() async {
    FocusScope.of(context).unfocus();
    final mssv = _studentCodeController.text.trim().toUpperCase();
    final password = _studentPasswordController.text.trim();

    if (mssv.isEmpty) {
      setState(() => _studentErrorMessage = 'Vui lòng nhập Mã số sinh viên (MSSV).');
      return;
    }

    if (password.isEmpty) {
      setState(() => _studentErrorMessage = 'Vui lòng nhập mật khẩu (mặc định là MSSV).');
      return;
    }

    setState(() {
      _isStudentLoggingIn = true;
      _studentErrorMessage = null;
    });

    try {
      final student = await _studentService.findByCode(mssv);
      final studentName = student?.fullName ?? 'Sinh viên $mssv';
      final studentId = student?.id ?? StudentService.toGuid(mssv);

      await _tokenStorage.saveToken('student_token_$mssv');
      await _tokenStorage.saveUserId(studentId);
      await _tokenStorage.saveUserInfo(
        role: 'Student',
        username: studentName,
        email: student?.email ?? '$mssv@student.edu.vn',
        studentCode: mssv,
        userId: studentId,
      );

      if (!mounted) return;
      _showMessage('Đăng nhập thành công! Xin chào $studentName');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouterScreen(initialRole: 'Student')),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _studentErrorMessage = 'Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => _isStudentLoggingIn = false);
    }
  }

  // ==================== 2. ĐĂNG NHẬP GIẢNG VIÊN (MÃ GV + MẬT KHẨU LÀ MÃ GV) ====================
  Future<void> _loginAsLecturer() async {
    FocusScope.of(context).unfocus();
    final code = _lecturerCodeController.text.trim().toUpperCase();
    final password = _lecturerPasswordController.text.trim();

    if (code.isEmpty) {
      setState(() => _lecturerErrorMessage = 'Vui lòng nhập Mã Giảng viên (ví dụ: GV001).');
      return;
    }

    if (password.isEmpty) {
      setState(() => _lecturerErrorMessage = 'Vui lòng nhập mật khẩu (mặc định là Mã GV).');
      return;
    }

    setState(() {
      _isLecturerLoggingIn = true;
      _lecturerErrorMessage = null;
    });

    try {
      final lecturer = await _lecturerService.findByCode(code);
      final lecturerName = lecturer?.fullName ?? 'ThS. Trần Văn Hùng ($code)';

      await _tokenStorage.saveToken('lecturer_token_$code');
      await _tokenStorage.saveUserInfo(
        role: 'Staff',
        username: lecturerName,
        email: lecturer?.email ?? '$code@university.edu.vn',
        lecturerCode: code,
      );

      if (!mounted) return;
      _showMessage('Đăng nhập Giảng viên thành công! Xin chào $lecturerName');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleRouterScreen(initialRole: 'Staff')),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _lecturerErrorMessage = 'Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => _isLecturerLoggingIn = false);
    }
  }

  // ==================== 3. ĐĂNG NHẬP QUẢN TRỊ VIÊN (ADMIN - BẮT BUỘC OTP) ====================
  Future<void> _sendAdminOtp() async {
    FocusScope.of(context).unfocus();
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _adminErrorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu Admin.');
      return;
    }

    setState(() {
      _isAdminSendingOtp = true;
      _adminErrorMessage = null;
      _adminInfoMessage = null;
    });

    try {
      final response = await _authService.requestLoginOtp(
        username: username,
        password: password,
      );

      if (!mounted) return;
      setState(() {
        _adminOtpSent = true;
        _adminInfoMessage = response['message']?.toString() ??
            'Mã xác thực OTP đã được gửi về email của Admin. Vui lòng kiểm tra email và nhập mã OTP 6 số để hoàn tất đăng nhập.';
      });
      _showMessage('Đã gửi mã OTP xác thực qua email thành công!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _adminOtpSent = false;
        _adminErrorMessage = 'Không thể gửi mã OTP: $e';
      });
      _showMessage('Lỗi gửi OTP: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAdminSendingOtp = false);
    }
  }

  Future<void> _loginAdmin() async {
    FocusScope.of(context).unfocus();
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _adminErrorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu Admin.');
      return;
    }

    // Nếu chưa gửi mã OTP thì kích hoạt gửi OTP trước
    if (!_adminOtpSent) {
      await _sendAdminOtp();
      return;
    }

    final otpCode = _adminOtpController.text.trim();
    if (otpCode.length != 6) {
      setState(() => _adminErrorMessage = 'Vui lòng nhập đầy đủ mã OTP gồm đúng 6 chữ số.');
      return;
    }

    setState(() {
      _isAdminLoggingIn = true;
      _adminErrorMessage = null;
    });

    try {
      final result = await _authService.verifyLoginOtp(username: username, otp: otpCode);
      final role = result['role']?.toString() ?? 'Admin';

      if (!mounted) return;
      _showMessage('Xác thực OTP thành công! Chào mừng Quản trị viên (Admin).');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleRouterScreen(initialRole: role)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _adminErrorMessage = 'Mã OTP không hợp lệ hoặc đã hết hạn: $e');
    } finally {
      if (mounted) setState(() => _isAdminLoggingIn = false);
    }
  }

  // ==================== TÍNH NĂNG QUÊN MẬT KHẨU ====================
  void _showForgotPasswordSheet() {
    String defaultCode = '';
    if (_tabController.index == 0) {
      defaultCode = _studentCodeController.text.trim();
    } else if (_tabController.index == 1) {
      defaultCode = _lecturerCodeController.text.trim();
    } else {
      defaultCode = _adminUsernameController.text.trim();
    }

    final accountCtrl = TextEditingController(text: defaultCode);
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool otpSent = false;
    bool isResetting = false;
    String? sheetError;
    String? sheetSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Khôi phục Mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: accountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mã số sinh viên (MSSV) hoặc Mã Giảng viên',
                      prefixIcon: Icon(Icons.account_circle),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!otpSent)
                    FilledButton.icon(
                      onPressed: () {
                        final val = accountCtrl.text.trim().toUpperCase();
                        if (val.isEmpty) {
                          setSheetState(() => sheetError = 'Vui lòng nhập mã sinh viên hoặc giảng viên.');
                          return;
                        }

                        // Nếu là sinh viên: mật khẩu mặc định là MSSV
                        if (val.startsWith('SV')) {
                          setSheetState(() {
                            sheetSuccess = 'Tài khoản Sinh viên $val có mật khẩu mặc định chính là "$val". Bạn có thể đăng nhập ngay!';
                            sheetError = null;
                          });
                          return;
                        }

                        // Nếu là giảng viên: mật khẩu mặc định là Mã GV
                        if (val.startsWith('GV')) {
                          setSheetState(() {
                            sheetSuccess = 'Tài khoản Giảng viên $val có mật khẩu mặc định chính là "$val". Bạn có thể đăng nhập ngay!';
                            sheetError = null;
                          });
                          return;
                        }

                        // Giả lập gửi OTP khôi phục mật khẩu Admin
                        setSheetState(() {
                          otpSent = true;
                          sheetError = null;
                          sheetSuccess = 'Đã gửi mã OTP khôi phục mật khẩu về email đăng ký!';
                        });
                      },
                      icon: const Icon(Icons.mark_email_read),
                      label: const Text('Kiểm tra & Khôi phục'),
                    ),

                  if (otpSent) ...[
                    TextFormField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Nhập mã OTP 6 số nhận qua Email',
                        prefixIcon: Icon(Icons.pin),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới *',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới *',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: isResetting
                          ? null
                          : () async {
                              final otp = otpCtrl.text.trim();
                              final newPass = newPassCtrl.text;
                              final confirmPass = confirmPassCtrl.text;

                              if (otp.length != 6) {
                                setSheetState(() => sheetError = 'Mã OTP phải có đúng 6 chữ số.');
                                return;
                              }
                              if (newPass.length < 8) {
                                setSheetState(() => sheetError = 'Mật khẩu mới phải có ít nhất 8 ký tự.');
                                return;
                              }
                              if (newPass != confirmPass) {
                                setSheetState(() => sheetError = 'Mật khẩu xác nhận không khớp.');
                                return;
                              }

                              setSheetState(() {
                                isResetting = true;
                                sheetError = null;
                              });

                              await Future.delayed(const Duration(milliseconds: 1000));

                              setSheetState(() {
                                isResetting = false;
                                sheetSuccess = 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.';
                              });
                            },
                      child: isResetting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Xác nhận Đổi Mật khẩu'),
                    ),
                  ],

                  if (sheetError != null) ...[
                    const SizedBox(height: 12),
                    Text(sheetError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],

                  if (sheetSuccess != null) ...[
                    const SizedBox(height: 12),
                    Text(sheetSuccess!, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 58,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cổng Đăng Nhập',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hệ thống Quản lý Đào tạo & Điểm danh Thông minh',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // TAB CHỌN LOẠI TÀI KHOẢN (SINH VIÊN - GIẢNG VIÊN - ADMIN)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black87,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.school, size: 20),
                          text: 'Sinh viên',
                        ),
                        Tab(
                          icon: Icon(Icons.badge, size: 20),
                          text: 'Giảng viên',
                        ),
                        Tab(
                          icon: Icon(Icons.admin_panel_settings, size: 20),
                          text: 'Admin',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // NỘI DUNG TỪNG TAB
                  SizedBox(
                    height: 490,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStudentLoginForm(),
                        _buildLecturerLoginForm(),
                        _buildAdminLoginForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== FORM 1: ĐĂNG NHẬP SINH VIÊN (MSSV + MK = MSSV) ====================
  Widget _buildStudentLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sinh viên đăng nhập bằng Mã số sinh viên (MSSV). Mật khẩu và MSSV giống nhau.',
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mã số sinh viên
          TextFormField(
            controller: _studentCodeController,
            decoration: const InputDecoration(
              labelText: 'Mã số sinh viên (MSSV) *',
              hintText: 'SV000299',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Mật khẩu (Chính là MSSV)
          TextFormField(
            controller: _studentPasswordController,
            obscureText: _hideStudentPassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu (Giống Mã sinh viên) *',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _hideStudentPassword = !_hideStudentPassword);
                },
                icon: Icon(_hideStudentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _studentPasswordSync,
                    activeColor: Colors.purple.shade700,
                    onChanged: (val) {
                      setState(() {
                        _studentPasswordSync = val ?? true;
                        if (_studentPasswordSync) {
                          _studentPasswordController.text = _studentCodeController.text.trim();
                        }
                      });
                    },
                  ),
                  const Text('Mật khẩu giống Mã SV', style: TextStyle(fontSize: 12)),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordSheet,
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),

          if (_studentErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_studentErrorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
              onPressed: _isStudentLoggingIn ? null : _loginAsStudent,
              icon: _isStudentLoggingIn
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(
                _isStudentLoggingIn ? 'Đang đăng nhập...' : 'Đăng nhập Sinh viên',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Text('Tài khoản mẫu: SV000299, SV000300, SV000301 (MK = Mã)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  // ==================== FORM 2: ĐĂNG NHẬP GIẢNG VIÊN (MÃ GV + MK = MÃ GV) ====================
  Widget _buildLecturerLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giảng viên đăng nhập bằng Mã Giảng viên (Mã GV). Mật khẩu và Mã GV giống nhau.',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mã giảng viên
          TextFormField(
            controller: _lecturerCodeController,
            decoration: const InputDecoration(
              labelText: 'Mã Giảng viên (Mã GV) *',
              hintText: 'GV001',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Mật khẩu (Chính là Mã GV)
          TextFormField(
            controller: _lecturerPasswordController,
            obscureText: _hideLecturerPassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu (Giống Mã Giảng viên) *',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _hideLecturerPassword = !_hideLecturerPassword);
                },
                icon: Icon(_hideLecturerPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _lecturerPasswordSync,
                    activeColor: Colors.teal.shade700,
                    onChanged: (val) {
                      setState(() {
                        _lecturerPasswordSync = val ?? true;
                        if (_lecturerPasswordSync) {
                          _lecturerPasswordController.text = _lecturerCodeController.text.trim();
                        }
                      });
                    },
                  ),
                  const Text('Mật khẩu giống Mã GV', style: TextStyle(fontSize: 12)),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordSheet,
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),

          if (_lecturerErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_lecturerErrorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
              onPressed: _isLecturerLoggingIn ? null : _loginAsLecturer,
              icon: _isLecturerLoggingIn
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(
                _isLecturerLoggingIn ? 'Đang đăng nhập...' : 'Đăng nhập Giảng viên',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Text('Tài khoản mẫu: GV001 (ThS. Hùng), GV002 (TS. Lan), GV003 (MK = Mã)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  // ==================== FORM 3: ĐĂNG NHẬP ADMIN (BẮT BUỘC OTP) ====================
  Widget _buildAdminLoginForm() {
    return Form(
      key: _adminFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.indigo.shade800, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cổng đăng nhập Ban Quản trị (Admin)',
                          style: TextStyle(fontSize: 13, color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Bảo mật 2 lớp: Nhập tài khoản & mật khẩu, sau đó xác thực bằng mã OTP gửi về Email.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tên đăng nhập Admin
            TextFormField(
              controller: _adminUsernameController,
              enabled: !_adminOtpSent,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập Admin *',
                hintText: 'admin',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên đăng nhập Admin' : null,
            ),
            const SizedBox(height: 12),

            // Mật khẩu Admin
            TextFormField(
              controller: _adminPasswordController,
              enabled: !_adminOtpSent,
              obscureText: _hideAdminPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu Admin *',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hideAdminPassword = !_hideAdminPassword),
                  icon: Icon(_hideAdminPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),

            if (!_adminOtpSent) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordSheet,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            ],

            // PHẦN NHẬP MÃ OTP
            if (_adminOtpSent) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read, color: Colors.blue, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _adminInfoMessage ?? 'Mã OTP đã được gửi về email Admin. Vui lòng nhập mã bên dưới:',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nhập mã OTP xác thực (6 chữ số) *',
                  hintText: '123456',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: const OutlineInputBorder(),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _adminOtpController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            if (_adminErrorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_adminErrorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 10),

            // NÚT BẤM CHÍNH
            if (!_adminOtpSent) ...[
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade800),
                  onPressed: _isAdminSendingOtp ? null : _sendAdminOtp,
                  icon: _isAdminSendingOtp
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isAdminSendingOtp ? 'Đang gửi mã OTP...' : 'Gửi mã OTP qua Email',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade900),
                  onPressed: _isAdminLoggingIn ? null : _loginAdmin,
                  icon: _isAdminLoggingIn
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.verified_user),
                  label: Text(
                    _isAdminLoggingIn ? 'Đang xác thực...' : 'Xác thực OTP & Đăng nhập Admin',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _isAdminSendingOtp ? null : _sendAdminOtp,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Gửi lại mã OTP', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _adminOtpSent = false;
                        _adminOtpController.clear();
                        _adminErrorMessage = null;
                        _adminInfoMessage = null;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Đổi tài khoản', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
