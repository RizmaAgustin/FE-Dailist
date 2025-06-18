import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.43.248:8000/api';

  // SIGN UP
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return {'status': response.statusCode, 'body': jsonDecode(response.body)};
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan jaringan: ${e.message}');
    }
  }

  // SIGN IN
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
      return {'status': response.statusCode, 'body': jsonDecode(response.body)};
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan jaringan: ${e.message}');
    }
  }

  // ADD TASK / EDIT TASK
  static Future<Map<String, dynamic>> saveTask({
    String? token,
    int? taskId,
    required String title,
    String? description,
    required String category,
    required String priority,
    required DateTime deadline,
    required bool reminder,
    required bool isCompleted,
  }) async {
    final url =
        taskId == null
            ? Uri.parse('$baseUrl/tasks')
            : Uri.parse('$baseUrl/tasks/$taskId');

    final body = {
      'title': title,
      'description': description ?? '',
      'category': category,
      'priority': priority,
      'deadline': DateFormat('yyyy-MM-dd HH:mm:ss').format(deadline),
      'reminder': reminder ? '1' : '0',
      'is_completed': isCompleted ? '1' : '0',
    };

    try {
      final response =
          taskId == null
              ? await http.post(
                url,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: json.encode(body),
              )
              : await http.put(
                url,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: json.encode(body),
              );
      return {'status': response.statusCode, 'body': jsonDecode(response.body)};
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan jaringan: ${e.message}');
    }
  }

  // Fetch all tasks
  static Future<Map<String, dynamic>> fetchTasks({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/tasks');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return {'status': response.statusCode, 'body': jsonDecode(response.body)};
    } on SocketException {
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Kesalahan jaringan: ${e.message}');
    }
  }

  // Toggle task completion - sesuai dengan route Laravel-mu
  static Future<Map<String, dynamic>> toggleTaskCompletion({
    required String token,
    required int taskId,
    required bool isCompleted,
  }) async {
    final url = Uri.parse('$baseUrl/tasks/$taskId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'is_completed': isCompleted ? '1' : '0'}),
      );
      return {
        'status': response.statusCode,
        'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } catch (e) {
      throw Exception('Tidak dapat mengubah status tugas: $e');
    }
  }

  // Delete task
  static Future<Map<String, dynamic>> deleteTask({
    required String token,
    required int taskId,
  }) async {
    final url = Uri.parse('$baseUrl/tasks/$taskId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return {
        'status': response.statusCode,
        'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } catch (e) {
      throw Exception('Tidak dapat menghapus tugas: $e');
    }
  }

  // Logout user
  static Future<void> logoutUser(String token) async {
    final url = Uri.parse('$baseUrl/logout');
    try {
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (_) {}
  }
}
