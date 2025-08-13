import 'package:dio/dio.dart';
import 'api_exceptions.dart';
import 'dio_client.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

typedef Json = Map<String, dynamic>;
typedef FromJson<T> = T Function(dynamic data);

class ApiService {
  static const String _baseUrl = 'http://192.168.1.83:8080';

  final Dio _dio;
  final TokenStorage _storage;

  ApiService._(this._dio, this._storage);

  /// สำหรับ endpoint สาธารณะ
  factory ApiService.public() {
    final dio = createBaseDio(baseUrl: _baseUrl);
    final storage = TokenStorage();
    dio.options.extra['dio'] = dio;
    return ApiService._(dio, storage);
  }

  /// สำหรับ endpoint ส่วนตัว (ต้องมี token + auto refresh)
  factory ApiService.private({
    required Future<String?> Function(String? refreshToken) onRefreshToken,
  }) {
    final dio = createBaseDio(baseUrl: _baseUrl);
    final storage = TokenStorage();

    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        onRefreshToken: (rt) async {
          final newAccess = await onRefreshToken(rt);
          if (newAccess != null) {
            await storage.saveTokens(
              accessToken: newAccess,
              refreshToken: rt ?? '',
            );
          }
          return newAccess;
        },
      ),
    );

    dio.options.extra['dio'] = dio;

    return ApiService._(dio, storage);
  }

  // ========== Core Request ==========
  Future<T> _request<T>(
    String path, {
    String method = 'GET',
    Json? query,
    dynamic data,
    FromJson<T>? decoder,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.request(
        path,
        queryParameters: query,
        data: data,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
      );
      final body = res.data;

      if (decoder != null) {
        return decoder(body);
      }
      return body as T;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Network error';
      throw ApiException(msg.toString(), statusCode: code);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ========== Helpers ==========
  Future<T> get<T>(
    String path, {
    Json? query,
    FromJson<T>? decoder,
    CancelToken? cancelToken,
  }) => _request<T>(
    path,
    method: 'GET',
    query: query,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<T> post<T>(
    String path, {
    dynamic data, // เปลี่ยนจาก Map<dynamic, Map<String, int>> เป็น dynamic
    Json? query,
    FromJson<T>? decoder,
    CancelToken? cancelToken,
  }) => _request<T>(
    path,
    method: 'POST',
    data: data, // ส่ง data โดยตรง
    query: query,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<T> put<T>(
    String path, {
    dynamic data,
    Json? query,
    FromJson<T>? decoder,
    CancelToken? cancelToken,
  }) => _request<T>(
    path,
    method: 'PUT',
    data: data,
    query: query,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Json? query,
    FromJson<T>? decoder,
    CancelToken? cancelToken,
  }) => _request<T>(
    path,
    method: 'DELETE',
    data: data,
    query: query,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  // ========== Utility ==========
  Future<void> setTokens({required String access, required String refresh}) =>
      _storage.saveTokens(accessToken: access, refreshToken: refresh);

  Future<void> clearTokens() => _storage.clear();
}
