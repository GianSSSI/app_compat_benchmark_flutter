import 'package:dio/dio.dart';

class BenchmarkConfigApi {
  final Dio dio;

  BenchmarkConfigApi(this.dio);

  Future<Map<String, dynamic>> fetchConfig() async {
    final res = await dio.get(
      'https://uqcmerchantqalb.unifysyscontrol.com/index.php/qc_merchant_api/benchmark/fetch_config',
    );

    final data = res.data;

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    // sometimes backends return a stringified json
    if (data is String) {
      throw FormatException(
        'Expected JSON map but got String. Ensure server returns JSON object.',
      );
    }

    throw FormatException('Unexpected response type: ${data.runtimeType}');
  }
}
