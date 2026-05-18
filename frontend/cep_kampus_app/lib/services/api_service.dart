import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/source_document.dart';
import 'package:flutter/foundation.dart';

/// Response model returned from the /ask endpoint.
class AskResult {
  const AskResult({required this.answer, required this.sources});
  final String answer;
  final List<SourceDocument> sources;
}

/// Wraps all HTTP communication with the FastAPI backend.
/// All Dio errors are caught here and re-thrown as typed [AppException]s
/// so no raw Dio types ever reach the UI or provider layer.
class ApiService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request/response logging in debug mode only.
    assert(() {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
      return true;
    }());
  }

  late final Dio _dio;

  /// Sends [query] to the /ask endpoint and returns a structured [AskResult].
  /// Throws a subclass of [AppException] on any failure.
  Future<AskResult> ask(String query) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.askEndpoint,
        data: {'query': query},
      );

      final body = response.data!;
      final sources = (body['sources'] as List<dynamic>? ?? [])
          .map((s) => SourceDocument.fromJson(s as Map<String, dynamic>))
          .toList();

      return AskResult(
        answer: body['answer'] as String? ?? '',
        sources: sources,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final detail = (e.response?.data as Map?)?['detail'] as String?;
        return ServerException(
          detail ?? 'Sunucu hatası (HTTP $code)',
          statusCode: code,
        );
      default:
        return UnknownException(e.message ?? 'Bilinmeyen bir hata oluştu.');
    }
  }
}