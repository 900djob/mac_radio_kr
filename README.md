# mac_radio_kr

한국 라디오를 재생하는 macOS 메뉴 막대 앱입니다. Flutter와 AppKit으로 만들었습니다.

## 미리보기

| 메뉴 막대 플레이어 | 지역·방송사별 채널 선택 |
| :---: | :---: |
| <img src="docs/images/radio-panel.png" alt="메뉴 막대에서 열린 SBS 파워FM 플레이어" width="252"> | <img src="docs/images/channel-selection.png" alt="지역, 방송사, 채널 순서로 선택하는 메뉴" width="452"> |

## 다운로드 및 설치

[설치 ZIP 다운로드 (v1.0.1 · arm64)](https://github.com/900djob/mac_radio_kr/raw/76d1c4e08de525f3b6757dbf71862bd85076d5a1/%EC%84%A4%EC%B9%98%ED%8C%8C%EC%9D%BC/mac_radio_kr-v1.0.1-arm64.zip)

최신 설치파일은 [설치파일 폴더](./설치파일/)에서 확인할 수 있습니다. 폴더에서 ZIP 파일명을 클릭하면 상세 페이지가 열리며, `Download raw file` 또는 `View raw`를 눌러 다운로드합니다.

- 대상: Apple Silicon Mac (arm64)
- 요구 사항: macOS 14 이상

1. ZIP을 열고 `mac_radio_kr.app`을 압축 해제합니다.
2. 앱을 `응용 프로그램` 폴더로 옮깁니다.
3. 앱을 실행하고 메뉴 막대의 라디오 아이콘을 누릅니다.

앱은 공증되지 않았습니다. 신뢰할 수 있는 파일인지 확인한 뒤, 첫 실행이 차단되면 [Apple 안내](https://support.apple.com/en-us/102445)에 따라 `시스템 설정 → 개인정보 보호 및 보안`의 `Open Anyway`로 실행을 허용할 수 있습니다. Intel Mac에서는 실행할 수 없습니다.

`main`에 변경사항을 push하면 GitHub Actions가 버전을 올리고 설치 ZIP을 갱신합니다. `[skip ci]`가 포함된 commit은 빌드를 건너뜁니다. 버전은 ZIP 파일명과 앱 정보에 표시됩니다.

## 사용 방법

- 메뉴 막대의 라디오 아이콘을 눌러 플레이어를 엽니다.
- 채널 이름을 누르고 `지역 → 방송사 → 채널` 순서로 선택하면 재생을 시작합니다.
- 첫 실행은 MBC FM4U를 정지 상태로 엽니다. 이후에는 마지막 채널을 복원하며, 자동으로 재생하지 않습니다.
- 가운데 버튼으로 재생과 정지를 전환합니다.
- 패널 밖을 클릭하거나 `Esc`를 눌러 닫아도 재생은 계속됩니다.
- 음량은 macOS의 볼륨 키나 제어 센터에서 조절합니다.
- 더보기 메뉴에서 앱을 종료합니다.
- 재생을 시작한 뒤 미디어 키와 macOS Now Playing으로 제어할 수 있습니다. 다시 재생하면 생방송에 연결합니다.

## 개발 실행

필요 항목: macOS 14 이상, Flutter 3.41 이상, Xcode, CocoaPods.

```sh
flutter pub get
flutter run -d macos
```

## 주요 기능

- 전국·지역별 방송사와 공동체 라디오 채널을 제공합니다.
- `just_audio`로 HLS 스트림을 재생합니다. 채널 변경과 재시도 때 재생 주소를 다시 조회합니다.
- macOS 기본 메뉴로 지역·방송사별 채널을 탐색합니다.
- 라디오 게인은 30%이며, 앱 시작 시 시스템 볼륨은 바꾸지 않습니다.
- `shared_preferences`에는 마지막 채널 ID만 저장합니다.
- 편성표와 선곡 정보는 제공하지 않습니다.

## 스트림 안내

- 방송사 API와 HLS에 직접 연결하며 중계 서버는 사용하지 않습니다.
- 방송사별 주소와 조회 방식은 [radio.bsod.kr](https://github.com/BSofDeath/radio.bsod.kr/tree/main/functions/stream/url)를 참고했습니다.
- 일부 HTTP 스트림은 암호화되지 않습니다.
- EBS는 온에어 페이지에서 재생 주소를 찾고, 실패하면 공식 HLS 주소를 시도합니다.
- 주소 조회나 연결에 실패한 채널은 목록에서 제외했습니다. 주소가 복구되면 다시 추가할 수 있습니다.
- 방송사 API와 페이지 변경에 따라 재생 주소 조회 코드의 수정이 필요할 수 있습니다.

## 검증 및 빌드

```sh
flutter analyze
flutter test
flutter test integration_test/radio_catalog_streams_test.dart -d macos
flutter test integration_test/radio_playback_test.dart -d macos
flutter test integration_test/system_volume_test.dart -d macos
flutter build macos --release
```

- 일반 테스트: 채널 목록, URL 파싱, 시간 제한, 재생 상태 전환을 확인합니다.
- 카탈로그·재생 통합 테스트: 실제 방송 주소와 macOS 오디오 엔진을 확인합니다. 재생 테스트는 음량 0으로 실행합니다.
- 시스템 볼륨 테스트: 볼륨을 잠시 0으로 바꾼 뒤 원래 값으로 복원합니다. 조절을 지원하지 않거나 음소거된 장치는 건너뜁니다.

Release 앱 경로: `build/macos/Build/Products/Release/mac_radio_kr.app`.

Release 빌드는 현재 Mac의 아키텍처를 사용합니다. Apple Silicon 빌드는 arm64용입니다. 앱은 로컬 서명만 적용하며 공증이나 스토어 배포는 포함하지 않습니다.
