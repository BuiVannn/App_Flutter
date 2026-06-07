import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Client Holobox (Elder Care) — port HoloboxApi.kt.
class HoloboxApi {
  static const baseUrl = 'https://aitools.ptit.edu.vn';

  static const medicinePrompt =
      'Hãy phân tích hình ảnh này và nhận diện chính xác viên/vỉ thuốc trong ảnh. '
      '1) Loại trừ người dùng, chỉ tập trung vào thuốc. '
      '2) Cho biết: Tên thuốc, Công dụng chính, Liều dùng tham khảo, và Lưu ý quan trọng. '
      'Trả lời bằng tiếng Việt. TUYỆT ĐỐI KHÔNG dùng bảng hay Markdown phức tạp. '
      'Viết dưới dạng các đoạn văn ngắn hoặc liệt kê dòng đơn giản.';

  /// Gửi ảnh thuốc → trả về văn bản phân tích. Ném [HoloboxException] nếu lỗi.
  static Future<String> analyzeMedicine(File image) async {
    final uri = Uri.parse('$baseUrl/holobox/medician');
    final req = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = medicinePrompt
      ..files.add(await http.MultipartFile.fromPath('image', image.path))
      ..files.add(await http.MultipartFile.fromPath('image_file', image.path));
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        throw HoloboxException('Máy chủ lỗi (${resp.statusCode})');
      }
      return _extractGeminiText(resp.body);
    } on SocketException {
      throw HoloboxException(
          'Không có Internet (không tìm thấy máy chủ), kiểm tra mạng rồi thử lại');
    } on HttpException {
      throw HoloboxException('Mạng chậm, thử lại nhé');
    }
  }

  /// candidates[0].content.parts[0].text (định dạng Gemini).
  static String _extractGeminiText(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      final parts = ((candidates?.first
          as Map?)?['content'] as Map?)?['parts'] as List?;
      final text = (parts?.first as Map?)?['text'] as String?;
      return (text == null || text.trim().isEmpty) ? '' : text.trim();
    } catch (_) {
      return '';
    }
  }
}

class HoloboxException implements Exception {
  final String message;
  HoloboxException(this.message);
  @override
  String toString() => message;
}
