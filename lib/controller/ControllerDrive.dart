import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ModelDrive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Controllerdrive {
  final baseUrl = dotenv.env['BASE_URL'];
  final configId = dotenv.env['CONFIG_ID'];

  Future<ModelDrive> getTriggerValues() async {
    final response =
        await http.get(Uri.parse('${baseUrl}/api/rsam-config/${configId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      return ModelDrive.fromMap(data);
    } else {
      throw Exception('Gagal mengambil trigger dari API lokal');
    }
  }

  Future<void> updateTriggerValues(ModelDrive trigger) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print(token);

    final response = await http.patch(
      Uri.parse('${baseUrl}/api/rsam-config/${configId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: json.encode(trigger.toMap()),
    );

    print('Response status: ${response.statusCode}');
    print('Response data: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Gagal update trigger ke API lokal');
    }
  }

  Future<Map<String, String?>> uploadFileToLocalApi(File file) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (!file.path.toLowerCase().endsWith('.mp3')) {
      throw Exception('Hanya file .mp3 yang diperbolehkan');
    }

    Dio dio = Dio();
    String fileName = basename(file.path);
    print('ini FE (Dio): ' + file.path);

    FormData formData = FormData.fromMap({
      'mp3_file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType('audio', 'mpeg'),
      ),
    });

    try {
      Response response = await dio.post(
        '${baseUrl}/api/files/upload-mp3',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Dio akan mengatur 'Content-Type': 'multipart/form-data' secara otomatis
          },
        ),
        onSendProgress: (int sent, int total) {
          print('Progress: ${(sent / total * 100).toStringAsFixed(2)}%');
        },
      );

      // API Anda mengembalikan 200 atau 201 untuk sukses
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('File berhasil diunggah: ${response.data}');
        // Asumsikan backend mengembalikan JSON seperti:
        // { "success": true, "fileId": "...", "fileUrl": "...", "fileName": "..." }
        if (response.data is Map<String, dynamic>) {
          // Kembalikan detail file yang relevan
          return {
            'fileUrl': response.data['fileUrl'] as String?,
            'fileName': response.data['fileName'] as String?,
            'fileId': response.data['fileId'] as String?, // Jika diperlukan di masa depan
          };
        } else {
          throw Exception('Format respons tidak terduga dari API unggah file');
        }
      } else {
        // Tangani status code error lainnya
        String errorMessage = 'Gagal mengunggah file: Status ${response.statusCode}';
        if (response.data != null) {
          errorMessage += ' - Data: ${response.data}';
        }
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal mengunggah file (DioException): ';
      if (e.response != null) {
        errorMessage += 'Status: ${e.response?.statusCode}, Data: ${e.response?.data}';
      } else {
        errorMessage += e.message ?? 'Unknown Dio error';
      }
      print(errorMessage); // Cetak pesan error untuk debugging
      throw Exception(errorMessage);
    } catch (e) {
      print('Terjadi kesalahan lain saat unggah: $e'); // Cetak pesan error untuk debugging
      throw Exception('Gagal mengunggah file karena kesalahan tak terduga: $e');
    }
  }
}
