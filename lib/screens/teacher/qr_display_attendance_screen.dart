import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nguyenhuudung/services/class_student_service.dart';

class QrDisplayAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String courseClassCode;
  final String sessionTitle;

  const QrDisplayAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.courseClassCode,
    this.sessionTitle = 'Buổi học',
  });

  @override
  State<QrDisplayAttendanceScreen> createState() => _QrDisplayAttendanceScreenState();
}

class _QrDisplayAttendanceScreenState extends State<QrDisplayAttendanceScreen> {
  final _service = ClassStudentService();
  List<SessionAttendanceDetail> _attendanceList = [];
  bool _isLoading = true;
  late String _qrPayload;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _generateQrPayload();
    _loadAttendance();
    ClassStudentService.attendanceChangeNotifier.addListener(_onAttendanceChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _silentlyRefreshAttendance();
    });
  }

  void _onAttendanceChanged() {
    if (mounted) _silentlyRefreshAttendance();
  }

  @override
  void dispose() {
    ClassStudentService.attendanceChangeNotifier.removeListener(_onAttendanceChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateQrPayload() {
    final payloadMap = {
      'type': 'attendance_qr',
      'sessionId': widget.sessionId,
      'classCode': widget.courseClassCode,
      'sessionTitle': widget.sessionTitle,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _qrPayload = jsonEncode(payloadMap);
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final list = await _service.getSessionAttendance(widget.sessionId, widget.courseClassCode);
    if (!mounted) return;
    setState(() {
      _attendanceList = list;
      _isLoading = false;
    });
  }

  Future<void> _silentlyRefreshAttendance() async {
    final list = await _service.getSessionAttendance(widget.sessionId, widget.courseClassCode);
    if (!mounted) return;
    setState(() {
      _attendanceList = List<SessionAttendanceDetail>.from(list);
    });
  }

  ImageProvider? _safeImageProvider(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final str = raw.trim();
    if (str.startsWith('http://') || str.startsWith('https://')) {
      if (!str.contains('.svg') && !str.contains('/svg')) return NetworkImage(str);
      return null;
    }
    try {
      String clean = str;
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return MemoryImage(base64Decode(clean));
    } catch (_) {
      return null;
    }
  }

  void _showStudentScanDetail(SessionAttendanceDetail item) {
    final imageProvider = _safeImageProvider(item.capturedFaceBase64);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.isPresent ? 'Thông tin có mặt: ${item.studentName}' : 'Chi tiết: ${item.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: item.isPresent ? Colors.green : Colors.grey.shade400, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.isPresent && imageProvider != null
                      ? Image(image: imageProvider, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            item.isPresent ? Icons.face : Icons.person_off,
                            size: 60,
                            color: item.isPresent ? Colors.green.shade700 : Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('• Họ tên: ${item.studentName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('• MSSV: ${item.studentCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('• Trạng thái: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.status == 0
                        ? Colors.green.shade50
                        : (item.status == 2
                            ? Colors.orange.shade50
                            : (item.status == 3 ? Colors.blue.shade50 : Colors.red.shade50)),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.status == 0
                          ? Colors.green
                          : (item.status == 2
                              ? Colors.orange
                              : (item.status == 3 ? Colors.blue : Colors.red)),
                    ),
                  ),
                  child: Text(
                    item.status == 0
                        ? 'CÓ MẶT (Present)'
                        : (item.status == 2
                            ? 'ĐI MUỘN (Late)'
                            : (item.status == 3 ? 'CÓ PHÉP (Excused)' : 'VẮNG MẶT (Absent)')),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: item.status == 0
                          ? Colors.green.shade800
                          : (item.status == 2
                              ? Colors.orange.shade800
                              : (item.status == 3 ? Colors.blue.shade800 : Colors.red.shade800)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (item.isPresent || item.status == 0 || item.status == 2) ...[
              Text('• Khuôn mặt xác thực: ${item.isFaceVerified ? "Hợp lệ (Đã đối soát)" : (item.faceMatchScore != null ? "${item.faceMatchScore!.toStringAsFixed(1)}% (>= 80% Đạt)" : "Đã xác thực")}'),
              Text('• Tọa độ GPS: ${item.gpsCoordinates ?? (item.latitude != null ? "${item.latitude}, ${item.longitude}" : "Đã xác thực vị trí")}'),
              Text('• Thời gian điểm danh: ${item.markedAt != null ? item.markedAt!.toLocal().toString().substring(11, 19) : "Vừa xong"}'),
              if (item.deviceInfo != null && item.deviceInfo!.isNotEmpty) Text('• Thiết bị: ${item.deviceInfo!}'),
            ] else ...[
              const Text(
                '• Sinh viên chưa hoàn thành quy trình điểm danh (Quét mã QR + Nhận diện khuôn mặt + Vị trí GPS).',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (item.note != null && item.note!.isNotEmpty) Text('• Ghi chú: ${item.note!}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _showFullScreenQr() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Mã QR Điểm danh (Chiếu máy chiếu)'),
            actions: [
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lớp: ${widget.courseClassCode} - ${widget.sessionTitle}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Sinh viên mở ứng dụng và quét mã QR này để điểm danh', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 320,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Đóng toàn màn hình'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendanceList.where((a) => a.isPresent).length;
    final totalCount = _attendanceList.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Điểm danh: ${widget.courseClassCode}'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới danh sách',
            onPressed: _loadAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD TẠO MÃ QR ĐIỂM DANH
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MÃ QR ĐIỂM DANH BUỔI HỌC',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    widget.sessionTitle,
                                    style: TextStyle(color: Colors.teal.shade800, fontSize: 13),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.teal),
                                tooltip: 'Chiếu toàn màn hình',
                                onPressed: _showFullScreenQr,
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Hiển thị QR Code
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade300, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                              ),
                              child: QrImageView(
                                data: _qrPayload,
                                version: QrVersions.auto,
                                size: 180,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.fullscreen, size: 18),
                                label: const Text('Phóng to trình chiếu'),
                                onPressed: _showFullScreenQr,
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.sync),
                                tooltip: 'Tạo mã QR mới',
                                onPressed: () {
                                  setState(_generateQrPayload);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã làm mới mã QR điểm danh')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.teal.shade900),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Quy trình điểm danh: Giảng viên chiếu mã QR trên lớp -> Sinh viên dùng app quét QR -> Quét khuôn mặt AI -> Lấy vị trí GPS -> Trạng thái tự động cập nhật "Có mặt" kèm ảnh và vị trí ngay tại đây (tự làm mới mỗi 3 giây).',
                                    style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // THỐNG KÊ SĨ SỐ THỜI GIAN THỰC
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sĩ số điểm danh: $presentCount / $totalCount có mặt',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            totalCount > 0 ? '${((presentCount / totalCount) * 100).toStringAsFixed(0)}%' : '0%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DANH SÁCH SINH VIÊN (CÓ MẶT / VẮNG TỰ ĐỘNG THEO KẾT QUẢ ĐIỂM DANH)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách sinh viên trong lớp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Tự động đồng bộ theo kết quả SV quét',
                        style: TextStyle(color: Colors.teal.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attendanceList.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _attendanceList[index];
                      final isPresent = item.isPresent;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _showStudentScanDetail(item),
                          leading: CircleAvatar(
                            backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                            backgroundImage: _safeImageProvider(item.capturedFaceBase64),
                            child: _safeImageProvider(item.capturedFaceBase64) == null
                                ? Icon(
                                    isPresent ? Icons.check_circle : Icons.cancel,
                                    color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(item.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(item.studentCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPresent ? 'Có mặt' : 'Vắng mặt',
                                      style: TextStyle(
                                        color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (isPresent && item.faceMatchScore != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mặt: ${item.faceMatchScore!.toStringAsFixed(1)}%',
                                      style: const TextStyle(fontSize: 11, color: Colors.teal),
                                    ),
                                  ],
                                  if (isPresent && item.gpsCoordinates != null) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.location_on, size: 12, color: Colors.blue),
                                    const Text(' GPS OK', style: TextStyle(fontSize: 11, color: Colors.blue)),
                                  ],
                                ],
                              ),
                              if (isPresent && item.gpsCoordinates != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${item.gpsCoordinates!}',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (item.markedAt != null)
                                Text(
                                  'Điểm danh lúc: ${item.markedAt!.toLocal().toString().substring(11, 19)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPresent ? Colors.green.shade400 : Colors.red.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPresent ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPresent ? 'CÓ MẶT' : 'VẮNG MẶT',
                                  style: TextStyle(
                                    color: isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
