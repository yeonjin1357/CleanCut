# 애드몹 광고 최적화 가이드

## 📊 개선된 기능

### 1. 재시도 로직 구현
- **지수 백오프**: 2초, 4초, 8초... 최대 32초
- **최대 재시도**: 3회
- **No Fill 처리**: 광고 인벤토리 부족 시 더 긴 대기

### 2. 적응형 배너 크기
- 화면 크기에 맞춰 자동 조정
- 더 높은 수익률

### 3. 광고 미리 로드
- 전면 광고 2개 동시 관리
- 표시 지연 최소화

### 4. 에러 코드별 처리
```dart
// 주요 에러 코드
- Code 0: ERROR_CODE_INTERNAL_ERROR
- Code 1: ERROR_CODE_INVALID_REQUEST  
- Code 2: ERROR_CODE_NETWORK_ERROR
- Code 3: ERROR_CODE_NO_FILL (광고 인벤토리 부족)
```

## 🚀 실제 광고로 전환하기

### 1단계: 애드몹 계정 설정
1. [애드몹 콘솔](https://apps.admob.com) 접속
2. 앱 등록
3. 광고 단위 생성
   - 배너 광고 단위
   - 전면 광고 단위

### 2단계: 광고 ID 교체
`lib/services/ad_service.dart` 파일에서:

```dart
// 현재 (테스트 ID)
static const String _prodBannerAdUnitId = 'YOUR_ACTUAL_BANNER_AD_ID';
static const String _prodInterstitialAdUnitId = 'YOUR_ACTUAL_INTERSTITIAL_AD_ID';

// 변경 후 (실제 ID) - 예시
static const String _prodBannerAdUnitId = 'ca-app-pub-1234567890123456/1234567890';
static const String _prodInterstitialAdUnitId = 'ca-app-pub-1234567890123456/0987654321';
```

### 3단계: 테스트 기기 등록
콘솔에서 표시되는 기기 ID를 추가:

```dart
testDeviceIds: <String>[
  'EMULATOR',
  'SIMULATOR', 
  'YOUR_ACTUAL_DEVICE_ID', // 예: '33BE2250B43518CCDA7DE426D04EE231'
],
```

### 4단계: app-ads.txt 설정
1. 웹사이트 루트에 `app-ads.txt` 파일 생성
2. 애드몹 콘솔에서 제공하는 내용 추가:
```
google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0
```

## 📈 수익 최적화 팁

### 1. 전면 광고 표시 전략
- **현재**: 5회 작업당 1회 표시
- **권장**: 사용자 경험 vs 수익 균형 조정
```dart
// 조정 가능한 빈도
if (_processCount % 3 == 0) { // 3회마다
  await _adService.showInterstitialAd();
}
```

### 2. 배너 광고 위치
- 화면 하단 고정 (현재)
- 콘텐츠와 자연스럽게 통합

### 3. 메디에이션 추가 (선택)
여러 광고 네트워크 통합으로 Fill Rate 향상:
- Facebook Audience Network
- Unity Ads
- AppLovin

## 🔍 모니터링

### 디버그 로그 확인
```bash
flutter run --verbose
```

### 주요 지표
- **Fill Rate**: 광고 요청 대비 성공률
- **eCPM**: 1000회 노출당 수익
- **CTR**: 클릭률

## ⚠️ 주의사항

### 정책 준수
1. 자체 광고 클릭 금지
2. 클릭 유도 금지
3. 광고 가리기 금지
4. 부적절한 트래픽 금지

### 테스트 시
- 개발 중에는 **반드시 테스트 광고** 사용
- 실제 광고 과도한 클릭 시 계정 정지 위험

## 📱 추가 개선 아이디어

### 1. 리워드 광고 도입
```dart
// 사용자에게 보상 제공
RewardedAd.load(
  adUnitId: rewardedAdUnitId,
  request: AdRequest(),
  // ...
);
```

### 2. 네이티브 광고
콘텐츠와 자연스럽게 통합되는 광고

### 3. 앱 오프닝 광고
앱 시작 시 전체 화면 광고

## 🐛 문제 해결

### 광고가 안 나올 때
1. 인터넷 연결 확인
2. 광고 ID 확인
3. 테스트 모드 확인
4. 지역 제한 확인 (일부 국가)
5. 애드몹 계정 상태 확인

### 수익이 낮을 때
1. 광고 위치 최적화
2. 타겟팅 설정 확인
3. 메디에이션 추가 고려
4. 사용자 참여도 향상

## 📞 지원

- [애드몹 도움말](https://support.google.com/admob)
- [Flutter 애드몹 문서](https://developers.google.com/admob/flutter)
- [애드몹 커뮤니티](https://support.google.com/admob/community)