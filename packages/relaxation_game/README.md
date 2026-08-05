# Relaxation Game

환자 앱에 연결할 수 있도록 독립적으로 만든 애니팡 스타일 매치-3 게임입니다.
특정 게임의 캐릭터나 이미지 자산은 사용하지 않고 일반 동물 이모지와 자체 UI를 사용합니다.
`medical_app`과 `patient_app` 코드에 의존하지 않습니다.

## 독립 실행

```bash
cd packages/relaxation_game/example
flutter run -d emulator-5554
```

## 기능

- 8×8 동물 타일 보드
- 인접 타일 선택 및 교환
- 가로·세로 3개 이상 매칭
- 연쇄 제거, 낙하, 타일 재생성
- 교환, 제거, 낙하 단계별 애니메이션과 콤보 피드백
- 점수, 콤보, 30회 이동 제한
- 목표 점수와 게임 완료 화면
- 가능한 이동이 없을 때 자동 섞기
- 최고 점수, 최고 콤보, 플레이 횟수, 목표 달성 횟수 로컬 저장

기록은 `shared_preferences`의 비동기 저장 API를 사용하므로 앱을 종료하거나
새 게임을 시작해도 유지됩니다. 환자 개인정보나 서버 계정과는 연결하지 않습니다.

## 환자 앱 통합

환자 앱 담당자가 `patient_app/pubspec.yaml`에 로컬 패키지를 추가합니다.

```yaml
dependencies:
  relaxation_game:
    path: ../packages/relaxation_game
```

라우터에서 공개 화면을 사용합니다.

```dart
import 'package:relaxation_game/relaxation_game.dart';

GoRoute(
  path: '/relaxation-game',
  builder: (context, state) => const AnimalMatchGamePage(),
),
```

## 검증

```bash
cd packages/relaxation_game
flutter analyze
flutter test
```
