import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.getApiUrl(),
      connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
    ));
    
    // 인터셉터 추가 (디버깅용)
    if (AppConfig.showDebugInfo) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: false,
      ));
    }
  }
  
  Future<Uint8List?> removeBackground(File imageFile) async {
    try {
      // 파일 크기 체크
      final fileSize = await imageFile.length();
      if (fileSize > AppConfig.maxImageSize) {
        throw Exception('이미지 크기가 너무 큽니다 (최대 10MB)');
      }
      
      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Gradio API 형식에 맞게 요청
      Response response = await _dio.post(
        '/api/predict',
        data: {
          'data': [
            'data:image/png;base64,$base64Image'
          ]
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        // Gradio 응답에서 이미지 추출
        final data = response.data['data'];
        if (data != null && data.isNotEmpty) {
          String base64Result = data[0];
          
          // data:image/png;base64, 부분 제거
          if (base64Result.startsWith('data:image')) {
            base64Result = base64Result.split(',')[1];
          }
          
          return base64Decode(base64Result);
        }
      }
      
      throw Exception('서버 응답 오류: ${response.statusCode}');
      
    } on DioException catch (e) {
      // Dio 에러 처리
      String errorMessage = '네트워크 오류가 발생했습니다';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '연결 시간이 초과되었습니다';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '응답 시간이 초과되었습니다';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '서버에 연결할 수 없습니다';
      } else if (e.response != null) {
        errorMessage = '서버 오류: ${e.response?.statusCode}';
      }
      
      print('API Error: $errorMessage');
      throw Exception(errorMessage);
      
    } catch (e) {
      print('Unexpected error: $e');
      throw e;
    }
  }
  
  // 서버 상태 확인
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // 배치 처리 (여러 이미지)
  Future<List<Uint8List?>> removeBackgroundBatch(List<File> imageFiles) async {
    List<Uint8List?> results = [];
    
    for (var file in imageFiles) {
      try {
        final result = await removeBackground(file);
        results.add(result);
      } catch (e) {
        results.add(null);
      }
    }
    
    return results;
  }
}