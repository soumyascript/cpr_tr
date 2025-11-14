import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'https://dev.medtrainai.com/api';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // REAL LOGIN using your rootLogin endpoint
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Login API Response: ${response.statusCode}');
      print('Login API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // DEBUG: Print full response structure
        print('Full API Response Structure: $data');

        // SAFE PARSING - Handle nested structure
        final responseData = data['data'];

        if (responseData == null) {
          return {
            'success': false,
            'message': 'No data received from server'
          };
        }

        // SAFE ACCESS with null checks
        final token = responseData['token']?.toString();
        final userDetails = responseData['userDetails'];

        if (token == null) {
          return {
            'success': false,
            'message': 'No token received from server'
          };
        }

        if (userDetails == null) {
          return {
            'success': false,
            'message': 'No user details received from server'
          };
        }

        // Store the token and user data
        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_data', value: json.encode(userDetails));

        return {
          'success': true,
          'user': userDetails,
          'token': token
        };
      } else {
        // Handle error responses safely
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              'Login failed with status ${response.statusCode}';
          return {
            'success': false,
            'message': errorMessage
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Login failed with status ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // VERIFY TOKEN using your /me endpoint
  static Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode({}),
      );

      print('Verify Token Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'user': data,
        };
      } else {
        await clearAuthData();
        return {
          'success': false,
          'message': 'Session expired'
        };
      }
    } catch (e) {
      print('Verify token error: $e');
      await clearAuthData();
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }

  static Future<void> storeAuthData(String token, Map<String, dynamic> user) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_data', value: json.encode(user));
  }

  static Future<void> clearAuthData() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    // Verify token is still valid
    final result = await verifyToken();
    return result['success'];
  }
}