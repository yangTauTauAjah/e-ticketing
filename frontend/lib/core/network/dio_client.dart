import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider((ref) => DioClient());

class DioClient {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  DioClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token'; //
        }
        return handler.next(options);
      },
    ));
  }

  Dio get instance => _dio;
}