import 'package:dio/dio.dart';

class BenchmarkConfigApi {
  final Dio dio;
  final String baseUrl;

  BenchmarkConfigApi({required this.dio, required this.baseUrl});

  Future<Map<String, dynamic>> fetchConfig() async {
    final res = await dio.get(
      '$baseUrl/index.php/qc_merchant_api/benchmark/fetch_config',
    );

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
