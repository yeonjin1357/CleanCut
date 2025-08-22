# CleanCut 환경 변수 설정 가이드

## 🔒 보안 주의사항
**절대로 API 토큰이나 민감한 정보를 코드에 직접 넣지 마세요!**

## 📋 설정 방법

### 1. `.env` 파일 생성
프로젝트 루트 디렉토리에서:
```bash
cp .env.example .env
```

### 2. API 토큰 설정

#### Replicate API 사용 시 (유료, 빠름)
1. [Replicate](https://replicate.com/account/api-tokens)에서 API 토큰 발급
2. `.env` 파일 열어서 수정:
```env
API_PROVIDER=replicate
REPLICATE_API_TOKEN=your_actual_replicate_token_here
```

#### Hugging Face Spaces 사용 시 (무료, 느림)
```env
API_PROVIDER=huggingface
HUGGINGFACE_URL=https://yeonjin98-cleancut-api.hf.space
```

### 3. 옵션 설정
```env
# 타임아웃 설정 (밀리초)
CONNECTION_TIMEOUT=15000  # 연결 타임아웃
RECEIVE_TIMEOUT=30000     # 응답 타임아웃

# 디버그 모드
DEBUG_MODE=false          # true로 설정하면 디버그 정보 표시
```

## 🚀 실행 방법

### 개발 환경
```bash
flutter run
```

### 프로덕션 빌드

#### Android
```bash
flutter build apk --release
```

#### iOS (Mac 필요)
```bash
flutter build ios --release
```

## 🔐 보안 체크리스트

- [ ] `.env` 파일이 `.gitignore`에 포함되어 있는지 확인
- [ ] 실제 API 토큰이 GitHub에 업로드되지 않았는지 확인
- [ ] 프로덕션 빌드 전 `DEBUG_MODE=false` 설정
- [ ] API 토큰 정기적으로 교체

## 🆘 문제 해결

### "환경 변수를 찾을 수 없습니다" 오류
1. `.env` 파일이 프로젝트 루트에 있는지 확인
2. `pubspec.yaml`의 assets에 `.env`가 포함되어 있는지 확인
3. `flutter clean && flutter pub get` 실행

### API 토큰이 작동하지 않음
1. 토큰이 올바르게 복사되었는지 확인
2. 토큰 앞뒤 공백 제거
3. API_PROVIDER 설정이 올바른지 확인

## 📝 환경 변수 목록

| 변수명 | 설명 | 기본값 | 필수 |
|--------|------|--------|------|
| API_PROVIDER | API 제공자 (replicate/huggingface) | huggingface | ✅ |
| REPLICATE_API_TOKEN | Replicate API 토큰 | - | Replicate 사용 시 |
| HUGGINGFACE_URL | Hugging Face Spaces URL | https://yeonjin98-cleancut-api.hf.space | ❌ |
| CONNECTION_TIMEOUT | 연결 타임아웃 (ms) | 15000 | ❌ |
| RECEIVE_TIMEOUT | 응답 타임아웃 (ms) | 30000 | ❌ |
| DEBUG_MODE | 디버그 모드 활성화 | false | ❌ |