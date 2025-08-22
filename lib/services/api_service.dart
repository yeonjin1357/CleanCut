import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  static int _requestCount = 0; // 요청 횟수 추적 (cold start 판단용)

  ApiService() {
    // Replicate와 Hugging Face에 따라 다른 설정
    if (AppConfig.useReplicate) {
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.getApiUrl(),
          connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
          receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
          headers: {
            'Authorization': 'Bearer ${AppConfig.replicateApiToken}',
            'Content-Type': 'application/json',
          },
        ),
      );
    } else {
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.getApiUrl(),
          connectTimeout: Duration(milliseconds: 60000), // HF는 더 느림
          receiveTimeout: Duration(milliseconds: 300000), // HF는 더 느림
        ),
      );
    }

    // 인터셉터 추가 (디버깅용)
    if (AppConfig.showDebugInfo) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: AppConfig.useReplicate, // HF는 바이너리라 로그 제외
        ),
      );
    }
  }

  Future<Uint8List?> removeBackground(
    File imageFile, {
    Function(double progress, String stage)? onProgress,
  }) async {
    // API 종류에 따라 다른 처리
    if (AppConfig.useReplicate) {
      return _removeBackgroundReplicate(imageFile, onProgress: onProgress);
    } else {
      return _removeBackgroundHuggingFace(imageFile, onProgress: onProgress);
    }
  }

  // Replicate API 사용
  Future<Uint8List?> _removeBackgroundReplicate(
    File imageFile, {
    Function(double progress, String stage)? onProgress,
  }) async {
    try {
      // 파일 크기 체크
      final fileSize = await imageFile.length();
      if (fileSize > AppConfig.maxImageSize) {
        throw Exception('이미지 크기가 너무 큽니다 (최대 10MB)');
      }

      // 파일 확장자 체크
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!AppConfig.allowedImageTypes.contains(extension)) {
        throw Exception('지원하지 않는 이미지 형식입니다');
      }

      // 이미지를 base64로 인코딩 (크기 최적화)
      final bytes = await imageFile.readAsBytes();

      final base64Image = base64Encode(bytes);
      final dataUri = 'data:image/$extension;base64,$base64Image';

      onProgress?.call(0.2, 'uploading');

      // 1. Replicate에 예측 요청 생성
      final createResponse = await _dio.post(
        AppConfig.predictionsEndpoint,
        data: {
          'version': AppConfig.modelVersion,
          'input': {
            'image': dataUri,
          },
        },
      );

      if (createResponse.statusCode != 201) {
        throw Exception('예측 생성 실패: ${createResponse.statusCode}');
      }

      final predictionId = createResponse.data['id'];
      final predictionUrl = createResponse.data['urls']['get'];

      if (AppConfig.showDebugInfo) {
        print('Prediction created: $predictionId');
      }

      onProgress?.call(0.3, 'processing');

      // 2. 폴링으로 결과 확인 (Replicate는 빠름 - 최대 30초)
      String? outputUrl;
      int attempts = 0;
      const maxAttempts = 60; // 30초 (0.5초마다 체크)
      const pollInterval = Duration(milliseconds: 500); // 0.5초마다 체크

      while (attempts < maxAttempts) {
        await Future.delayed(pollInterval);

        final statusResponse = await _dio.get(predictionUrl);
        final status = statusResponse.data['status'];

        if (AppConfig.showDebugInfo) {
          print('Prediction status: $status (attempt ${attempts + 1})');
        }

        // 진행률 업데이트 (30% ~ 85%) - Replicate는 보통 2-5초 내 완료
        // 처음 5초 동안 빠르게 진행, 이후 천천히
        double progress;
        final elapsedSeconds = (attempts * 0.5);
        if (elapsedSeconds <= 5) {
          // 5초 이내: 30% -> 75% (빠르게)
          progress = 0.3 + (elapsedSeconds / 5 * 0.45);
        } else {
          // 5초 이후: 75% -> 85% (천천히)
          progress = 0.75 + ((elapsedSeconds - 5) / 25 * 0.1);
        }
        onProgress?.call(progress.clamp(0.3, 0.85), 'processing');

        if (status == 'succeeded') {
          // output이 문자열 또는 배열일 수 있음
          final output = statusResponse.data['output'];
          if (output is String) {
            outputUrl = output;
          } else if (output is List && output.isNotEmpty) {
            outputUrl = output[0];
          }
          break;
        } else if (status == 'failed' || status == 'canceled') {
          final error = statusResponse.data['error'];
          throw Exception('처리 실패: $status${error != null ? ' - $error' : ''}');
        }

        attempts++;
      }

      if (outputUrl == null) {
        throw Exception('처리 시간 초과 (30초)');
      }

      onProgress?.call(0.9, 'downloading');

      // 3. 결과 이미지 다운로드
      final imageResponse = await _dio.get(
        outputUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {}, // Authorization 헤더 제거 (이미지 URL은 공개)
        ),
      );

      if (imageResponse.statusCode == 200) {
        onProgress?.call(1.0, 'completed');
        return imageResponse.data;
      }

      throw Exception('이미지 다운로드 실패: ${imageResponse.statusCode}');
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
        // Replicate API 에러 메시지 파싱
        if (e.response?.statusCode == 401) {
          errorMessage = 'API 토큰이 유효하지 않습니다';
        } else if (e.response?.statusCode == 402) {
          errorMessage = 'Replicate 크레딧이 부족합니다. 계정에 크레딧을 충전해주세요.';
        } else if (e.response?.statusCode == 422) {
          errorMessage = '잘못된 요청 형식입니다';
        } else {
          errorMessage = '서버 오류: ${e.response?.statusCode}';
        }
      }

      print('API Error: $errorMessage');
      if (e.response?.data != null) {
        print('Error details: ${e.response?.data}');
      }
      throw Exception(errorMessage);
    } catch (e) {
      print('Unexpected error: $e');
      throw e;
    }
  }

  // Hugging Face Spaces API 사용 (기존 방식)
  Future<Uint8List?> _removeBackgroundHuggingFace(
    File imageFile, {
    Function(double progress, String stage)? onProgress,
  }) async {
    try {
      // 파일 크기 체크
      final fileSize = await imageFile.length();
      if (fileSize > AppConfig.maxImageSize) {
        throw Exception('이미지 크기가 너무 큽니다 (최대 10MB)');
      }

      // 파일 확장자 체크
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!AppConfig.allowedImageTypes.contains(extension)) {
        throw Exception('지원하지 않는 이미지 형식입니다');
      }

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'image.$extension',
        ),
      });

      // 서버 처리 시간 예측 (Hugging Face 무료 스페이스는 매우 느림)
      // Cold start 고려: 첫 요청은 모델 로딩으로 훨씬 더 오래 걸림
      final isFirstRequest = _requestCount == 0;
      final baseTime = isFirstRequest ? 60.0 : 30.0; // 첫 요청은 60초 기본, 이후 30초
      final sizeBasedTime = fileSize / 1024 / 1024 * 15; // MB당 15초 (무료 CPU 환경)
      final estimatedProcessingTime = (baseTime + sizeBasedTime).clamp(
        30.0,
        240.0,
      ); // 최소 30초, 최대 4분
      DateTime? uploadCompleteTime;
      DateTime? processStartTime;

      Response response = await _dio.post(
        AppConfig.removeBackgroundEndpoint,
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: (sent, total) {
          // 업로드 진행률: 0-20%
          final uploadProgress = sent / total;
          final totalProgress = uploadProgress * 0.2; // 전체의 20%
          onProgress?.call(totalProgress, 'uploading');

          if (uploadProgress >= 1.0 && uploadCompleteTime == null) {
            uploadCompleteTime = DateTime.now();
            processStartTime = DateTime.now();

            // 서버 처리 진행률 시뮬레이션 시작 (20-90%)
            _simulateProcessingProgress(
              onProgress,
              estimatedProcessingTime,
              processStartTime!,
            );
          }

          if (AppConfig.showDebugInfo) {
            print(
              'Upload progress: ${(uploadProgress * 100).toStringAsFixed(0)}%',
            );
          }
        },
        onReceiveProgress: (received, total) {
          // 다운로드 진행률: 85-100%
          if (total > 0) {
            final downloadProgress = received / total;
            final totalProgress = 0.85 + (downloadProgress * 0.15); // 85-100%
            onProgress?.call(totalProgress, 'downloading');
          }

          if (AppConfig.showDebugInfo) {
            print(
              'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      if (response.statusCode == 200) {
        _requestCount++; // 성공한 요청 카운트 증가
        onProgress?.call(1.0, 'completed');
        return response.data;
      }

      throw Exception('서버 응답 오류: ${response.statusCode}');
    } on DioException catch (e) {
      // Dio 에러 처리
      String errorMessage = '네트워크 오류가 발생했습니다';

      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '연결 시간이 초과되었습니다';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '응답 시간이 초과되었습니다 (Hugging Face 무료 서버가 느립니다)';
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

  // 서버 처리 진행률 시뮬레이션 (20-90%)
  void _simulateProcessingProgress(
    Function(double, String)? onProgress,
    double estimatedTime,
    DateTime startTime,
  ) async {
    if (onProgress == null) return;

    const updateInterval = Duration(milliseconds: 500); // 업데이트 간격 늘림 (성능 향상)
    const startProgress = 0.2; // 20%
    const endProgress = 0.90; // 90%까지 진행 (다운로드 여유 10%)

    bool shouldContinue = true;

    while (shouldContinue) {
      await Future.delayed(updateInterval);

      final elapsed =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final progress = (elapsed / estimatedTime).clamp(0.0, 1.0);

      // 로그 함수로 더 자연스러운 진행률 (처음엔 빠르게, 나중엔 매우 천천히)
      // ln(1 + 9x) / ln(10) 형태로 진행률 계산
      final logProgress = math.log(1 + 9 * progress) / math.log(10);
      final totalProgress =
          startProgress + (logProgress * (endProgress - startProgress));

      // 진행률 업데이트
      onProgress(totalProgress.clamp(startProgress, endProgress), 'processing');

      // 90%에 도달하거나 예상 시간의 2배가 지나면 중단
      if (totalProgress >= endProgress - 0.01 || elapsed > estimatedTime * 2) {
        shouldContinue = false;
      }

      // 디버그 정보
      if (AppConfig.showDebugInfo) {
        print(
          'Processing simulation: ${(totalProgress * 100).toStringAsFixed(1)}% (elapsed: ${elapsed.toStringAsFixed(1)}s)',
        );
      }
    }
  }

  // 서버 상태 확인
  Future<bool> checkHealth() async {
    try {
      if (AppConfig.useReplicate) {
        // API 토큰 유효성 확인을 위해 간단한 GET 요청
        final response = await _dio.get('/');
        return response.statusCode == 200;
      } else {
        final response = await _dio.get(AppConfig.healthCheckEndpoint);
        return response.statusCode == 200;
      }
    } catch (e) {
      return false;
    }
  }

  // 배치 처리 (여러 이미지)
  Future<List<Uint8List?>> removeBackgroundBatch(
    List<File> imageFiles, {
    Function(double progress, String stage)? onProgress,
  }) async {
    List<Uint8List?> results = [];

    for (var i = 0; i < imageFiles.length; i++) {
      try {
        final result = await removeBackground(
          imageFiles[i],
          onProgress: onProgress != null
              ? (progress, stage) {
                  // 전체 진행률 계산
                  final overallProgress = (i + progress) / imageFiles.length;
                  onProgress(overallProgress, stage);
                }
              : null,
        );
        results.add(result);
      } catch (e) {
        results.add(null);
      }
    }

    return results;
  }
}
