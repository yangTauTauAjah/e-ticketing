import 'package:dio/dio.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider((ref) => DioClient(ref));

class DioClient {
  final Dio _dio = Dio();

  DioClient(Ref ref) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).value?.token;
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Dio get instance => _dio;
}