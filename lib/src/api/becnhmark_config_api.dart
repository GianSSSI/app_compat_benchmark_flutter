import 'package:dio/dio.dart';

class BenchmarkConfigApi {
  final Dio dio;
  final String configUrl;

  BenchmarkConfigApi({required this.dio, required this.configUrl});

  Future<Map<String, dynamic>> fetchConfig() async {
    final res = await dio.get(configUrl);

    final data = res.data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      throw FormatException(
        'Expected JSON map but got String. Ensure server returns JSON object.',
      );
    }

    throw FormatException('Unexpected response type: ${data.runtimeType}');
  }
}
