import 'package:dio/dio.dart';

Dio createDioClient() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        // Add auth headers here if needed
      },
    ),
  );
}
