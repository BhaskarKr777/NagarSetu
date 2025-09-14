import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/report.dart';

class ApiService {
  // IMPORTANT: Replace with your actual IP address
  // For Android Emulator, use 10.0.2.2
  // For physical device, use your computer's local network IP
  static const String _baseUrl = "http://192.168.1.17:5000";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  ApiService() {
    // Configure Dio with default settings
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  static String getBaseUrl() => _baseUrl;

  Future<String?> _getToken() async {
    try {
      return await _storage.read(key: 'jwt_token');
    } catch (e) {
      debugPrint('Error reading token: $e');
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      await _storage.write(key: 'jwt_token', value: token);
      debugPrint('Token saved successfully');
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'jwt_token');
      debugPrint('Token deleted successfully');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }

  Future<bool> login(String phone) async {
    if (phone.trim().isEmpty) {
      throw Exception('Phone number cannot be empty');
    }

    try {
      debugPrint('Attempting login for phone: $phone');
      
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': phone.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
          return true;
        } else {
          throw Exception('No token received from server');
        }
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server error. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<bool> signup(String phone, String name) async {
    if (phone.trim().isEmpty || name.trim().isEmpty) {
      throw Exception('Phone number and name cannot be empty');
    }

    try {
      debugPrint('Attempting signup for phone: $phone, name: $name');
      
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'phone': phone.trim(),
              'name': name.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Signup response status: ${response.statusCode}');
      debugPrint('Signup response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
          return true;
        } else {
          throw Exception('No token received from server');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Phone number already exists');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Signup failed');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server error. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      debugPrint('Signup error: $e');
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<List<Report>> getReports() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please login again.');
    }

    try {
      debugPrint('Fetching reports...');
      
      final response = await http
          .get(
            Uri.parse('$_baseUrl/reports'),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Get reports response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Received ${data.length} reports');
        
        return data.map((json) {
          try {
            return Report.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing report: $e');
            debugPrint('Report data: $json');
            rethrow;
          }
        }).toList();
      } else if (response.statusCode == 401) {
        await logout(); // Clear invalid token
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server error. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      debugPrint('Get reports error: $e');
      throw Exception('Failed to load reports: ${e.toString()}');
    }
  }

  Future<bool> createReport({
    required String title,
    required String description,
    required String category,
    File? mediaFile,
    double? latitude,
    double? longitude,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please login again.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Title cannot be empty');
    }

    try {
      debugPrint('Creating report: $title');
      
      final formData = FormData.fromMap({
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      });

      if (mediaFile != null) {
        debugPrint('Adding media file: ${mediaFile.path}');
        formData.files.add(MapEntry(
          'media',
          await MultipartFile.fromFile(mediaFile.path),
        ));
      }

      final response = await _dio.post(
        '$_baseUrl/report',
        data: formData,
        options: Options(
          headers: {'Authorization': token},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('Create report response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        debugPrint('Report created successfully');
        return true;
      } else if (response.statusCode == 401) {
        await logout(); // Clear invalid token
        throw Exception('Session expired. Please login again.');
      } else {
        final error = response.data['error'] ?? 'Failed to create report';
        throw Exception(error);
      }
    } on DioException catch (e) {
      debugPrint('Dio error creating report: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        throw Exception('Failed to create report: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected error creating report: $e');
      throw Exception('Failed to create report: ${e.toString()}');
    }
  }

  // Helper method to check if backend is reachable
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      return false;
    }
  }
}