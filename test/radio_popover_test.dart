import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Slider;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mac_radio_kr/main.dart';
import 'package:mac_radio_kr/menu_bar_bridge.dart';
import 'package:mac_radio_kr/radio_channel.dart';
import 'package:mac_radio_kr/radio_controller.dart';
import 'package:mocktail/mocktail.dart';

class DisplayController extends Mock implements RadioController {}

class DisplayBridge extends Mock implements MenuBarBridge {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fontFile = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
    if (await fontFile.exists()) {
      final fontData = ByteData.sublistView(await fontFile.readAsBytes());
      for (final family in ['CupertinoSystemText', 'CupertinoSystemDisplay']) {
        final loader = FontLoader(family)..addFont(Future.value(fontData));
        await loader.load();
      }
    }
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await icons.load();
  });
  testWidgets('220x172 panel aligns every state in light and dark appearance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 344);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    final controller = DisplayController();
    final bridge = DisplayBridge();
    when(() => bridge.updateStatus(any())).thenAnswer((_) async {});

    for (final brightness in Brightness.values) {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          brightness;
      for (final status in RadioStatus.values) {
        when(() => controller.status).thenReturn(status);
        when(
          () => controller.channel,
        ).thenReturn(RadioChannel.byId('kbs_hanminjok'));
        final capture = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: ColoredBox(
              color: brightness == Brightness.dark
                  ? const Color(0xFF303033)
                  : const Color(0xFFD5D5D7),
              child: MacRadioApp(
                key: ValueKey('$brightness-$status'),
                controller: controller,
                bridge: bridge,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$brightness-$status');
        expect(find.text('KBS 한민족방송'), findsOneWidget);
        expect(find.byType(Slider), findsNothing);
        final artwork = tester.getRect(
          find.ancestor(of: find.text('KBS'), matching: find.byType(Container)),
        );
        final channel = tester.getRect(find.text('KBS 한민족방송'));
        final actions = tester.getRect(find.byIcon(CupertinoIcons.ellipsis));
        final playback = tester.getRect(
          status == RadioStatus.connecting
              ? find.byType(CupertinoActivityIndicator)
              : find.byIcon(
                  status == RadioStatus.playing
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.play_fill,
                ),
        );
        expect(channel.left, artwork.left);
        expect(playback.center.dx, (artwork.right + actions.right) / 2);
        expect(playback.center.dy, artwork.center.dy);
        expect(artwork.left, greaterThan(12));
        expect(find.byIcon(CupertinoIcons.backward_end_fill), findsNothing);
        expect(find.byIcon(CupertinoIcons.forward_end_fill), findsNothing);

        const directory = String.fromEnvironment('UI_CAPTURE_DIRECTORY');
        if (directory.isNotEmpty && status == RadioStatus.stopped) {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$directory/radio-panel-${brightness.name}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });
}
