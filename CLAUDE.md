# Flutter 앱 개발 가이드라인

## 기술 스택

### 핵심 기술

- **Flutter** (Dart)
- **크로스 플랫폼** 지원 (iOS/Android)
- **Provider** 패턴 (상태 관리)
- **SQLite** (sqflite) - 로컬 데이터 저장
- **SharedPreferences** - 간단한 설정값 저장

### 자주 사용하는 패키지

```yaml
dependencies:
  provider: ^6.1.1
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^17.2.4
  material_symbols_icons: ^4.2668.0
  flutter_localizations:
    sdk: flutter
```

## Dart 코딩 규칙

### 명명 규칙

- **클래스명**: PascalCase (예: `WaterIntake`)
- **파일명**: snake_case (예: `water_intake.dart`)
- **변수/함수**: camelCase (예: `dailyGoal`, `calculateProgress()`)
- **상수**: lowerCamelCase 또는 SCREAMING_SNAKE_CASE
- **Private 멤버**: 언더스코어로 시작 (예: `_privateMethod()`)

### 필수 준수 사항

```dart
// ✅ 좋은 예시
class ServiceClass {
  final DatabaseHelper _dbHelper;
  late final StreamController<int> _controller;

  // null safety 항상 고려
  Future<int?> getData() async {
    try {
      final result = await _dbHelper.query();
      return result?.value;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  // dispose 메서드 구현
  void dispose() {
    _controller.close();
  }
}

// ❌ 피해야 할 예시
class service_class {  // 잘못된 명명
  var dbHelper;  // 타입 미지정

  getData() {  // 반환 타입 미지정
    // try-catch 없음
    return dbHelper.query();
  }
  // dispose 없음
}
```

### 주요 체크리스트

1. **Null Safety**: 모든 변수에 null 가능성 명시 (`?`, `!`, `late`)
2. **타입 명시**: `var` 대신 명확한 타입 사용
3. **에러 처리**: try-catch 블록으로 예외 처리
4. **비동기 처리**: async/await 올바른 사용
5. **메모리 관리**: StreamController, AnimationController 등은 반드시 dispose
6. **const 활용**: 가능한 곳에서 const 생성자 사용
7. **주석**: 복잡한 로직에만 간단한 주석 추가

### 자주 하는 실수 방지

```dart
// setState 중복 호출 방지
if (mounted) {
  setState(() {
    // UI 업데이트
  });
}

// BuildContext 안전한 사용
await someAsyncWork();
if (context.mounted) {  // ✅ 비동기 후 context 체크
  Navigator.push(context, ...);
}

// List 초기화
const List<String> items = [];  // ✅ 불변 리스트
final List<String> items = [];  // ✅ 가변 리스트
```

## 프로젝트 구조

```
lib/
├── models/       # 데이터 모델 클래스
├── screens/      # 화면 위젯
├── widgets/      # 재사용 가능한 컴포넌트
├── services/     # 비즈니스 로직, API, DB
├── providers/    # 상태 관리 Provider
├── utils/        # 헬퍼 함수, 유틸리티
├── constants/    # 색상, 텍스트 상수, 테마
└── localization/ # 다국어 지원
```

## 상태 관리 전략

### Provider 패턴

- **전역 상태**: 앱 전체에서 공유하는 데이터
- **로컬 상태**: 특정 화면에서만 사용하는 데이터
- **ChangeNotifier**: 상태 변경 알림

```dart
// Provider 기본 구조
class AppProvider extends ChangeNotifier {
  // Private 상태
  String _data = '';

  // Getter
  String get data => _data;

  // 상태 변경 메서드
  void updateData(String newData) {
    _data = newData;
    notifyListeners();  // 필수!
  }

  // 비동기 초기화
  Future<void> initialize() async {
    // 데이터 로드
    notifyListeners();
  }

  @override
  void dispose() {
    // 리소스 정리
    super.dispose();
  }
}
```

## 성능 최적화

### 필수 최적화 사항

1. **백그라운드 작업 최소화**
2. **애니메이션은 60fps 유지**
3. **메모리 누수 방지 (dispose 철저히 구현)**
4. **이미지 최적화 (적절한 크기와 포맷)**
5. **불필요한 리빌드 방지**

```dart
// const 위젯 활용
const MyWidget();  // 리빌드 방지

// ListView.builder 사용 (대량 데이터)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// 무거운 연산은 compute 사용
final result = await compute(heavyFunction, data);
```

## 데이터 저장 전략

### SharedPreferences (간단한 설정)

```dart
// 저장
final prefs = await SharedPreferences.getInstance();
await prefs.setString('key', value);
await prefs.setInt('count', 10);
await prefs.setBool('isDarkMode', true);

// 불러오기
final value = prefs.getString('key') ?? 'default';
final count = prefs.getInt('count') ?? 0;
final isDarkMode = prefs.getBool('isDarkMode') ?? false;
```

### SQLite (복잡한 데이터)

```dart
// 기본 데이터베이스 구조
class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}
```

## UI/UX 원칙

### 디자인 가이드라인

1. **Material 3 디자인 시스템 사용**
2. **반응형 레이아웃 (다양한 화면 크기)**
3. **일관된 색상 테마**
4. **직관적인 네비게이션**

## 개발 작업 원칙 (Claude Code 사용 시)

### 점진적 개발 접근

- **한 번에 하나의 기능**에만 집중
- 대량의 코드 변경 시 단계별로 나누어 작업
- 각 단계마다 검증 후 다음 단계 진행

### 작업량 제한

- 한 번에 **최대 100-150줄** 정도의 코드만 추가/수정
- 복잡한 기능은 여러 단계로 분할
- 큰 작업은 명확히 구분하여 진행

### 품질 유지 방법

1. **작은 단위로 작업**: 한 번에 한 파일 또는 한 기능
2. **즉시 테스트**: 각 변경 후 바로 실행 확인
3. **단계별 커밋**: 의미 있는 단위로 구분
4. **명확한 구분**: UI, 로직, 데이터 레이어 분리 작업

## 테스트 및 디버깅

### 디버그 출력

```dart
// 개발 중에만 출력
debugPrint('Debug message');

// 조건부 출력
if (kDebugMode) {
  print('Development only');
}
```

### 에러 처리

```dart
try {
  // 위험한 작업
  final result = await riskyOperation();
} catch (e, stackTrace) {
  debugPrint('Error: $e');
  debugPrint('Stack trace: $stackTrace');
  // 사용자에게 친화적인 메시지 표시
  showSnackBar('작업 중 오류가 발생했습니다');
}
```

## 빌드 및 배포

### Android 빌드

```bash
flutter build apk --release  # APK
flutter build appbundle --release  # AAB (Play Store)
```

### iOS 빌드 (Mac 필요)

```bash
flutter build ios --release
# 또는 Codemagic 같은 CI/CD 서비스 사용
```

### 버전 관리

`pubspec.yaml`:

```yaml
version: 1.0.0+1 # 버전+빌드번호
```

## 자주 사용하는 위젯 패턴

### 로딩 상태 처리

```dart
FutureBuilder<T>(
  future: loadData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return ContentWidget(data: snapshot.data!);
  },
);
```

### 리스트 아이템 삭제

```dart
Dismissible(
  key: Key(item.id),
  onDismissed: (direction) {
    removeItem(item.id);
  },
  child: ListTile(title: Text(item.name)),
);
```

## 주의사항

1. **iOS 시뮬레이터**: 일부 기능 제한 (카메라, 푸시 알림 등)
2. **Android 권한**: targetSdkVersion에 따라 권한 요청 방식 다름
3. **async/await**: UI 스레드 블로킹 주의
4. **메모리 관리**: 대용량 이미지나 리스트 처리 시 주의

## 유용한 도구

- **Flutter Inspector**: 위젯 트리 분석
- **DevTools**: 성능 프로파일링
- **Very Good CLI**: 프로젝트 템플릿 생성
- **FlutterGen**: 에셋 자동 생성

## 마지막으로...

- 사용자 피드백 적극 반영
- 꾸준한 업데이트와 버그 수정
- 코드 수정하고 테스트 한다고 flutter run 안해도 돼. 이미 안드로이드 시뮬레이터로 계속 확인하고 있으니깐!
