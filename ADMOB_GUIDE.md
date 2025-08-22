# AdMob 광고 설정 가이드

## 📱 현재 상태
- **테스트 광고 ID 사용 중** (릴리즈 빌드 포함)
- 실제 수익은 발생하지 않음
- 광고가 정상적으로 표시되는지 테스트 가능

## ⚠️ 중요 사항

### 테스트 광고 관련
1. **현재 모든 환경에서 테스트 광고 표시**
   - 배너: `ca-app-pub-3940256099942544/6300978111`
   - 전면: `ca-app-pub-3940256099942544/1033173712`

2. **테스트 광고는 수익이 발생하지 않음**
   - 실제 광고 ID 필요

3. **Google Play Store 배포 시 주의**
   - 테스트 광고로는 정식 배포 불가능
   - 반드시 실제 광고 ID로 변경 필요

## 🚀 실제 광고 ID 설정 방법

### 1단계: AdMob 계정 설정
1. [AdMob 콘솔](https://apps.admob.com) 접속
2. 계정이 없다면 생성
3. 앱 추가:
   - 앱 이름: CleanCut
   - 플랫폼: Android
   - 패키지명: `com.example.cleancut` (또는 실제 패키지명)

### 2단계: 광고 유닛 생성
1. **배너 광고 유닛**
   - 광고 형식: 배너
   - 이름: CleanCut Banner
   - ID 복사 (예: `ca-app-pub-XXXXX/YYYYY`)

2. **전면 광고 유닛**
   - 광고 형식: 전면
   - 이름: CleanCut Interstitial
   - ID 복사 (예: `ca-app-pub-XXXXX/ZZZZZ`)

### 3단계: 코드 수정
`lib/services/ad_service.dart` 파일에서:

```dart
// 1. 실제 광고 ID 입력 (17-18번 줄)
static const String _prodBannerAdUnitId = 'ca-app-pub-실제ID/배너ID';
static const String _prodInterstitialAdUnitId = 'ca-app-pub-실제ID/전면ID';

// 2. 테스트 코드 삭제, 주석 해제 (22-25번 줄)
// 이 부분 삭제:
String get bannerAdUnitId => _testBannerAdUnitId;
String get interstitialAdUnitId => _testInterstitialAdUnitId;

// 이 부분 주석 해제:
String get bannerAdUnitId => kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
String get interstitialAdUnitId => kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
```

### 4단계: 테스트 디바이스 등록 (선택)
개발 중 실제 광고를 보면서 테스트하려면:

1. 앱 실행 후 로그에서 디바이스 ID 확인:
   ```
   I/Ads: Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))
   ```

2. `ad_service.dart`의 73번 줄에 추가:
   ```dart
   testDeviceIds: <String>[
     'EMULATOR',
     'SIMULATOR',
     '33BE2250B43518CCDA7DE426D04EE231', // 여기에 실제 디바이스 ID
   ],
   ```

## 🐛 문제 해결

### 광고가 안 나올 때
1. **No Fill (에러 코드 3)**
   - 정상적인 현상 (광고 재고 부족)
   - 자동 재시도 로직이 작동함

2. **Invalid Request**
   - 광고 ID 확인
   - 패키지명이 AdMob 설정과 일치하는지 확인

3. **Network Error**
   - 인터넷 연결 확인
   - VPN 사용 시 끄고 테스트

### 광고 로드 디버깅
`ad_service.dart`에 디버그 로그가 포함되어 있음:
- `[HOME BANNER]`: 홈 화면 배너
- `[EDITOR BANNER]`: 편집 화면 배너
- `[INTERSTITIAL]`: 전면 광고
- `[PRELOAD]`: 미리 로드된 광고

## 📊 수익 최적화 팁

1. **광고 빈도 조절**
   - 너무 자주 보여주면 사용자 이탈
   - 너무 적으면 수익 감소

2. **전면 광고 타이밍**
   - 현재: 처리 완료, 다운로드, 공유 시
   - 추가 고려: 앱 시작 시 (하루 1회)

3. **eCPM 모니터링**
   - AdMob 콘솔에서 확인
   - 지역별, 시간대별 차이 분석

4. **A/B 테스트**
   - 광고 위치
   - 광고 빈도
   - 광고 형식

## 📱 앱 배포 체크리스트

- [ ] 실제 AdMob 광고 ID 설정
- [ ] 테스트 디바이스 ID 제거 (선택)
- [ ] 광고 정책 준수 확인
- [ ] 개인정보 처리방침에 광고 명시
- [ ] GDPR/COPPA 준수 (필요시)

## 🔗 유용한 링크

- [AdMob 시작 가이드](https://developers.google.com/admob/flutter/quick-start)
- [광고 정책](https://support.google.com/admob/answer/6128543)
- [수익 최적화 팁](https://admob.google.com/home/resources/optimize-ad-revenue/)
- [Flutter AdMob 패키지](https://pub.dev/packages/google_mobile_ads)

## 💡 참고사항

- 광고 수익은 즉시 발생하지 않음 (일일 정산)
- 최소 지급 금액: $100
- 계정 인증 필요 (주소, 세금 정보)
- 잘못된 클릭 방지 (본인/가족이 클릭하면 안됨)

---
*마지막 업데이트: 2025-08-22*