/// 앱 설정 파일
/// API URL 및 기타 설정 관리

class AppConfig {
  // === API 설정 ===
  // Hugging Face Spaces (무료) 또는 Replicate (유료) 선택
  static const bool useReplicate = false; // true: Replicate, false: Hugging Face

  // Replicate API 설정 (유료 - 크레디트 필요)
  // TODO: 실제 사용 시 API 토큰을 환경 변수나 별도 파일로 관리하세요
  // 보안상 토큰을 코드에 직접 넣지 마세요!
  static const String replicateApiToken = 'YOUR_REPLICATE_API_TOKEN_HERE';
  static const String replicateApiUrl = 'https://api.replicate.com/v1';
  static const String modelVersion =
      'f74986db0355b58403ed20963af156525e2891ea3c2d499bfbfb2a28cd87c5d7';

  // Hugging Face Spaces 설정 (무료)
  static const String huggingFaceUrl =
      'https://yeonjin98-cleancut-api.hf.space';

  // API 엔드포인트
  static const String predictionsEndpoint = '/predictions';
  static const String removeBackgroundEndpoint = '/remove-background';
  static const String healthCheckEndpoint = '/health';

  // 타임아웃 설정 (밀리초)
  static const int connectionTimeout = 15000; // 15초 (Replicate는 빠름)
  static const int receiveTimeout = 30000; // 30초 (Replicate 처리 시간)

  // 이미지 설정
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageWidth = 4096; // 최대 너비
  static const int maxImageHeight = 4096; // 최대 높이
  static const int minImageSize = 100; // 최소 크기 (너비/높이)
  static const int targetImageSize = 2048; // 리사이징 목표 크기
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // UI 설정
  static const bool showDebugInfo = true; // 디버그 정보 표시 여부 (테스트용으로 활성화)
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