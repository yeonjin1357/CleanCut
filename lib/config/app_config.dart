/// 앱 설정 파일
/// API URL 및 기타 설정 관리

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // === API 설정 ===
  // 환경 변수에서 API 제공자 확인 (replicate 또는 huggingface)
  static bool get useReplicate => 
      (dotenv.env['API_PROVIDER'] ?? 'huggingface').toLowerCase() == 'replicate';

  // Replicate API 설정 (유료 - 크레디트 필요)
  static String get replicateApiToken => 
      dotenv.env['REPLICATE_API_TOKEN'] ?? 'YOUR_REPLICATE_API_TOKEN_HERE';
  static const String replicateApiUrl = 'https://api.replicate.com/v1';
  static const String modelVersion =
      'f74986db0355b58403ed20963af156525e2891ea3c2d499bfbfb2a28cd87c5d7';

  // Hugging Face Spaces 설정 (무료)
  static String get huggingFaceUrl =>
      dotenv.env['HUGGINGFACE_URL'] ?? 'https://yeonjin98-cleancut-api.hf.space';

  // API 엔드포인트
  static const String predictionsEndpoint = '/predictions';
  static const String removeBackgroundEndpoint = '/remove-background';
  static const String healthCheckEndpoint = '/health';

  // 타임아웃 설정 (밀리초)
  static int get connectionTimeout => 
      int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '15000') ?? 15000;
  static int get receiveTimeout => 
      int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30000') ?? 30000;

  // 이미지 설정
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageWidth = 4096; // 최대 너비
  static const int maxImageHeight = 4096; // 최대 높이
  static const int minImageSize = 100; // 최소 크기 (너비/높이)
  static const int targetImageSize = 2048; // 리사이징 목표 크기
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // UI 설정
  static bool get showDebugInfo => 
      (dotenv.env['DEBUG_MODE'] ?? 'false').toLowerCase() == 'true';
  static const bool enableAnalytics = false; // 분석 도구 사용 여부

  // 서버 상태 확인
  static Future<bool> checkServerHealth() async {
    try {
      // TODO: 실제 헬스 체크 구현
      return true;
    } catch (e) {
      return false;
    }
  }

  // 환경별 URL 가져오기
  static String getApiUrl() {
    // useReplicate 설정에 따라 다른 URL 반환
    return useReplicate ? replicateApiUrl : huggingFaceUrl;
  }
}
