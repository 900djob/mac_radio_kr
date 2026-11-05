# mac_radio_kr

한국 라디오를 듣는 macOS 메뉴바 앱입니다. Flutter 화면과 재생 로직을 AppKit의 메뉴바 팝오버에 연결합니다.

## 실행

macOS 13 이상, Flutter 3.41 이상, Xcode, CocoaPods가 필요합니다.

```sh
flutter pub get
flutter run -d macos
```

앱을 실행하면 메뉴바의 라디오 아이콘만 나타납니다. 아이콘을 클릭해 패널을 열고 채널명으로 채널을 선택합니다. 이전·다음 버튼은 채널을 순환하고, 가운데 버튼은 재생·정지를 전환합니다. 패널을 닫아도 재생은 계속됩니다. 더보기 메뉴에서 앱을 종료합니다.

첫 실행은 MBC FM4U, 볼륨 50%, 정지 상태입니다. 마지막 채널과 볼륨만 저장하며 자동 재생하지 않습니다. 편성표, 선곡 정보와 지역 채널은 포함하지 않습니다.

## 구성

- Flutter: `RadioController`, `StreamUrlResolver`, 채널 목록, 420 × 200pt 패널 UI.
- AppKit: `NSStatusItem`, `NSPopover`, `NSVisualEffectView`, 네이티브 채널 메뉴와 엔진 수명 관리.
- 오디오: 하나의 `just_audio` 플레이어로 HLS 재생. 채널 변경·재시도 시 동적 URL을 새로 조회합니다.
- 채널: KBS 6개, MBC 2개, SBS 2개, CBS 2개, EBS FM으로 총 13개입니다.
- 저장: `shared_preferences`에 채널 ID와 볼륨만 저장합니다.

방송사별 주소와 조회 방식은 [BSofDeath/radio.bsod.kr](https://github.com/BSofDeath/radio.bsod.kr/tree/main/functions/stream/url)를 참고했습니다. 이 앱은 운영자의 중계 서버를 사용하지 않고 방송사 API와 HLS에 직접 연결합니다. EBS는 온에어 HTML의 재생 주소를 추출하고, 없으면 기존 공식 HLS 주소를 시도합니다. 방송사 API나 페이지 변경 시 조회 코드 갱신이 필요할 수 있습니다.

## 검증 및 빌드

```sh
flutter analyze
flutter test
flutter test integration_test/radio_playback_test.dart -d macos
flutter build macos --release
```

일반 테스트는 외부 네트워크 없이 응답 파싱, 제한 시간, 채널 전환 경쟁, 정지와 재시도를 검증합니다. 통합 테스트는 실제 네트워크·macOS 오디오 엔진을 사용해 13개 채널의 재생 상태와 오디오 버퍼 수신을 무음으로 확인합니다. 음량 0으로 수행하므로 실제 스피커 청취 확인과는 구분됩니다.

빌드 결과는 `build/macos/Build/Products/Release/mac_radio_kr.app`입니다. 개인 사용을 위한 로컬 서명만 적용하며 공증·스토어 배포는 포함하지 않습니다. 현재 Xcode의 `lipo` 다중 아키텍처 검증 오류 때문에 Release 빌드는 빌드하는 Mac의 아키텍처로 제한합니다. Apple Silicon에서 만든 앱은 arm64용이며, Intel Mac은 해당 환경에서 다시 빌드해야 합니다.
