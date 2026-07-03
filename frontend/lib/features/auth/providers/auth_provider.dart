import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthState {
  String? id;
  final String? role;
  final String? userName;
  final String? email;
  final DateTime? createdAt;
  final bool isAuthenticated;

  AuthState({
    this.id,
    this.role,
    this.userName,
    this.email,
    this.createdAt,
    this.isAuthenticated = false,
  });
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    if (token == null) return AuthState(isAuthenticated: false);

    try {
      final dio = ref.read(dioProvider).instance;
      final response = await dio.get(ApiConstants.profile);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return AuthState(
          id: data['id'],
          role: data['role'],
          userName: data['name'],
          email: data['email'],
          createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
          isAuthenticated: true,
        );
      }
    } catch (_) {
      await storage.delete(key: 'jwt_token');
    }
    return AuthState(isAuthenticated: false);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final dio = ref.read(dioProvider).instance;
    const storage = FlutterSecureStorage();

    state = await AsyncValue.guard(() async {
      final response = await dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final data = response.data['data'];
        await storage.write(key: 'jwt_token', value: data['token']); //
        
        return AuthState(
          id: data['id'],
          role: data['role'], // 'user', 'helpdesk', or 'admin'
          userName: data['name'],
          email: data['email'],
          isAuthenticated: true,
        );
      } else {
        throw Exception(response.data['message']);
      }
    });
  }

  Future<bool> register(
    String name,
    String email,
    String? phone,
    String password,
  ) async {
    state = const AsyncLoading();
  final dio = ref.read(dioProvider).instance;

  try {
    final response = await dio.post(ApiConstants.register, data: {
      'name': name,
      'username': name.toLowerCase().replaceAll(' ', ''),
      'email': email,
      'password': password,
      'phone': phone,
    });

    if (response.data['success']) {
      // Success, but don't log them in yet!
      state = AsyncData(AuthState(isAuthenticated: false)); 
      return true;
    } else {
      throw Exception(response.data['message']);
    }
  } catch (e) {
    state = AsyncError(e, StackTrace.current);
    return false;
  }
  }

  void logout() {
    state = AsyncData(AuthState(isAuthenticated: false));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});