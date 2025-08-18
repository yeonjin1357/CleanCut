# CleanCut 배포 가이드

## 🚀 서버 배포 (Hugging Face Spaces)

### 사전 준비
1. [Hugging Face](https://huggingface.co) 계정 생성
2. 이메일 인증 완료
3. Git 설치 확인: `git --version`

### Step 1: Space 생성

1. https://huggingface.co/spaces 접속
2. "Create new Space" 클릭
3. 설정:
   - Space name: `cleancut` (또는 원하는 이름)
   - Select the Space SDK: **Gradio** 선택
   - Space hardware: **CPU basic** (무료) 또는 **GPU** (유료 권장)
   - Public/Private: **Public** 선택

### Step 2: 파일 업로드

#### 방법 1: 웹 인터페이스 사용
1. Space 페이지에서 "Files" 탭 클릭
2. 다음 파일들 업로드:
   - `app.py` (Gradio 인터페이스)
   - `server_birefnet.py`
   - `requirements.txt`
   - `README.md`

#### 방법 2: Git 사용 (권장)
```bash
# Space 클론
git clone https://huggingface.co/spaces/YOUR_USERNAME/cleancut
cd cleancut

# 파일 복사
cp /path/to/your/app.py .
cp /path/to/your/server_birefnet.py .
cp /path/to/your/requirements.txt .

# Git 커밋 & 푸시
git add .
git commit -m "Initial deployment"
git push
```

### Step 3: requirements.txt 최적화

Hugging Face Spaces용 최적화된 버전:
```txt
# requirements_hf.txt
fastapi==0.109.0
uvicorn==0.27.0
python-multipart==0.0.6
gradio==4.16.0

# 이미지 처리
Pillow==10.2.0
numpy==1.24.3

# ML 모델
torch==2.1.2
torchvision==0.16.2
transformers==4.36.2
accelerate==0.25.0
timm==0.9.12
einops==0.7.0
```

### Step 4: Space 설정 (app.py 수정)

```python
# Space URL 확인 후 수정
SPACE_URL = "https://YOUR_USERNAME-cleancut.hf.space"
```

### Step 5: 배포 확인

1. Space 페이지에서 "Building" 상태 확인
2. 빌드 완료 후 앱 테스트
3. API 엔드포인트 확인: `https://YOUR_USERNAME-cleancut.hf.space/remove-background`

## 📱 Flutter 앱 배포

### Android (Google Play Store)

#### 1. 앱 서명 준비
```bash
# 키스토어 생성
keytool -genkey -v -keystore cleancut.keystore -alias cleancut -keyalg RSA -keysize 2048 -validity 10000
```

#### 2. build.gradle 설정
```gradle
// android/app/build.gradle
android {
    signingConfigs {
        release {
            keyAlias 'cleancut'
            keyPassword 'your_password'
            storeFile file('cleancut.keystore')
            storePassword 'your_password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 3. API URL 업데이트
```dart
// lib/config/app_config.dart
static const String apiBaseUrl = 'https://YOUR_USERNAME-cleancut.hf.space';
```

#### 4. 빌드
```bash
# AAB (권장)
flutter build appbundle --release

# APK
flutter build apk --release
```

#### 5. Play Console 업로드
1. https://play.google.com/console 접속
2. 새 앱 생성
3. AAB 파일 업로드
4. 스토어 정보 작성
5. 심사 제출

### iOS (App Store)

#### 1. Xcode 설정
```bash
# iOS 프로젝트 열기
open ios/Runner.xcworkspace
```

#### 2. 번들 ID 설정
- Xcode에서 Bundle Identifier 설정: `com.yourcompany.cleancut`
- Apple Developer 계정에서 App ID 생성

#### 3. 빌드
```bash
flutter build ios --release
```

#### 4. App Store Connect
1. https://appstoreconnect.apple.com 접속
2. 새 앱 생성
3. Xcode에서 Archive & Upload
4. TestFlight 테스트
5. 앱 심사 제출

## 🔧 환경별 설정

### 개발 환경
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String apiBaseUrl = 'http://10.0.2.2:8000'; // 로컬
}
```

### 스테이징 환경
```dart
class AppConfig {
  static const String apiBaseUrl = 'https://cleancut-staging.hf.space';
}
```

### 프로덕션 환경
```dart
class AppConfig {
  static const String apiBaseUrl = 'https://cleancut.hf.space';
}
```

## 📊 모니터링

### Hugging Face Spaces 모니터링
- Space 대시보드에서 로그 확인
- Usage 탭에서 리소스 사용량 확인
- Settings에서 환경 변수 설정

### 앱 모니터링
- Google Play Console: 크래시 리포트, 사용자 통계
- App Store Connect: 크래시 로그, 앱 분석
- Firebase Analytics: 사용자 행동 분석 (선택사항)

## 🚨 문제 해결

### Hugging Face Spaces 빌드 실패
```bash
# requirements.txt 버전 충돌 확인
pip install -r requirements.txt --dry-run

# 메모리 부족 시 GPU 업그레이드 고려
```

### API 연결 실패
1. CORS 설정 확인
2. Hugging Face Space URL 확인
3. 네트워크 권한 확인

### 앱 심사 거절
- 개인정보 처리방침 추가
- 이미지 사용 권한 명시
- 오프라인 모드 안내

## 📝 체크리스트

### 서버 배포
- [ ] Hugging Face 계정 생성
- [ ] Space 생성 및 설정
- [ ] 파일 업로드
- [ ] 빌드 성공 확인
- [ ] API 테스트

### Android 배포
- [ ] 키스토어 생성
- [ ] API URL 업데이트
- [ ] AAB 빌드
- [ ] Play Console 업로드
- [ ] 스토어 정보 작성

### iOS 배포
- [ ] Apple Developer 계정
- [ ] 인증서 설정
- [ ] 빌드 및 아카이브
- [ ] TestFlight 테스트
- [ ] App Store 제출

## 🎯 권장 배포 순서

1. **Hugging Face Spaces 배포** (무료, 즉시 가능)
2. **Android 베타 테스트** (Google Play Console)
3. **iOS TestFlight** (Apple)
4. **정식 출시**

## 💰 비용 예상

### 서버
- Hugging Face Spaces (CPU): **무료**
- Hugging Face Spaces (GPU): $0.60/시간
- AWS EC2 (g4dn.xlarge): ~$0.526/시간

### 앱 스토어
- Google Play: $25 (일회성)
- Apple Developer: $99/년

## 🔗 유용한 링크

- [Hugging Face Spaces 문서](https://huggingface.co/docs/hub/spaces)
- [Flutter 배포 가이드](https://docs.flutter.dev/deployment)
- [Google Play Console 가이드](https://support.google.com/googleplay/android-developer)
- [App Store Connect 가이드](https://developer.apple.com/app-store-connect/)