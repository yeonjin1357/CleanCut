# CleanCut 테스트 가이드

## 📋 테스트 체크리스트

### 1. 로컬 서버 테스트

#### Python 환경 설정
```bash
# Python 3.10+ 권장
python --version

# 가상 환경 생성 (선택사항)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 패키지 설치
pip install -r requirements.txt
```

#### 서버 실행
```bash
# 옵션 1: 실제 모델 사용 (GPU 권장)
python server_birefnet.py

# 옵션 2: 테스트 서버 (모델 없이)
python server_example.py
```

#### API 테스트
```bash
# 헬스 체크
curl http://localhost:8000/health

# API 문서 확인
# 브라우저에서: http://localhost:8000/docs

# 이미지 테스트 (curl 사용)
curl -X POST "http://localhost:8000/remove-background" \
  -F "file=@test_image.jpg" \
  --output result.png
```

### 2. Flutter 앱 테스트

#### 설정 변경
```dart
// lib/config/app_config.dart 수정

// Android 에뮬레이터
static const String apiBaseUrl = 'http://10.0.2.2:8000';

// iOS 시뮬레이터 또는 실제 기기 (같은 네트워크)
static const String apiBaseUrl = 'http://your-computer-ip:8000';
```

#### 앱 실행
```bash
# 패키지 설치
flutter pub get

# 디바이스 확인
flutter devices

# 앱 실행
flutter run

# 특정 디바이스 선택
flutter run -d device_id
```

### 3. 테스트 시나리오

#### ✅ 기본 기능 테스트
- [ ] 갤러리에서 이미지 선택
- [ ] 카메라로 사진 촬영
- [ ] 배경 제거 처리
- [ ] 결과 이미지 표시
- [ ] 원본/결과 비교
- [ ] 이미지 저장
- [ ] 이미지 공유

#### ✅ 에러 처리 테스트
- [ ] 네트워크 연결 끊김
- [ ] 서버 응답 없음
- [ ] 큰 이미지 파일 (10MB+)
- [ ] 지원하지 않는 형식
- [ ] 서버 에러 (500)

#### ✅ UI/UX 테스트
- [ ] 로딩 표시
- [ ] 에러 메시지
- [ ] 버튼 활성화/비활성화
- [ ] 화면 전환 애니메이션
- [ ] 다크 모드 (있는 경우)

### 4. 성능 테스트

#### 이미지 크기별 처리 시간
| 이미지 크기 | 예상 시간 (GPU) | 예상 시간 (CPU) |
|------------|----------------|----------------|
| 512x512    | 1-2초          | 5-10초         |
| 1024x1024  | 2-3초          | 10-20초        |
| 2048x2048  | 3-5초          | 20-40초        |

### 5. 문제 해결

#### 서버가 시작되지 않음
```bash
# 포트 확인
netstat -an | grep 8000

# 포트 종료 (Windows)
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# 포트 종료 (Mac/Linux)
lsof -i :8000
kill -9 <PID>
```

#### Flutter 앱이 서버에 연결되지 않음
1. 방화벽 설정 확인
2. 서버 IP 주소 확인: `ipconfig` (Windows) / `ifconfig` (Mac/Linux)
3. `app_config.dart`의 URL 확인
4. 같은 네트워크에 있는지 확인

#### 이미지 처리 실패
1. 이미지 형식 확인 (JPG, PNG, WEBP)
2. 이미지 크기 확인 (10MB 이하)
3. 서버 로그 확인
4. GPU 메모리 확인 (GPU 사용 시)

### 6. 디버깅 팁

#### Flutter 디버그 모드
```dart
// lib/config/app_config.dart
static const bool showDebugInfo = true; // 디버그 정보 활성화
```

#### 서버 로그 확인
```python
# server_birefnet.py
logging.basicConfig(level=logging.DEBUG)  # 상세 로그
```

#### 네트워크 모니터링
- Chrome DevTools Network 탭
- Postman으로 API 직접 테스트
- Charles Proxy 또는 Fiddler 사용

## 📱 디바이스별 주의사항

### Android
- 최소 API 레벨: 21
- 권한: 인터넷, 카메라, 저장소
- 에뮬레이터는 `10.0.2.2` 사용

### iOS
- 최소 iOS 버전: 12.0
- Info.plist 권한 설정 필요
- 시뮬레이터에서 카메라 사용 불가

## 🚀 다음 단계

테스트가 완료되면:
1. `DEPLOYMENT_GUIDE.md` 참조하여 배포
2. Hugging Face Spaces에 서버 배포
3. 앱스토어에 앱 제출

## 💡 유용한 명령어

```bash
# Flutter 관련
flutter doctor              # 환경 체크
flutter clean              # 캐시 정리
flutter pub upgrade        # 패키지 업데이트
flutter build apk          # Android APK 빌드
flutter logs               # 로그 확인

# Python 관련
pip list                   # 설치된 패키지 확인
python -m pytest tests/    # 테스트 실행 (있는 경우)
```