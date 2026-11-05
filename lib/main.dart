import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Tooltip,
        Material,
        MaterialType,
        Slider,
        SliderTheme,
        SliderThemeData,
        RoundSliderThumbShape,
        RoundSliderOverlayShape,
        ShowValueIndicator,
        DefaultMaterialLocalizations;
import 'package:shared_preferences/shared_preferences.dart';

import 'menu_bar_bridge.dart';
import 'radio_channel.dart';
import 'radio_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = RadioController(
    preferences: await SharedPreferences.getInstance(),
  );
  await controller.initialize();
  runApp(MacRadioApp(controller: controller));
}

class MacRadioApp extends StatefulWidget {
  const MacRadioApp({super.key, required this.controller, this.bridge});

  final RadioController controller;
  final MenuBarBridge? bridge;

  @override
  State<MacRadioApp> createState() => _MacRadioAppState();
}

class _MacRadioAppState extends State<MacRadioApp> {
  late final MenuBarBridge _bridge = widget.bridge ?? MenuBarBridge();
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateStatus);
    _updateStatus();
  }

  void _updateStatus() {
    final value =
        '${widget.controller.channel.name} · ${widget.controller.status.label}';
    if (_lastStatus == value) return;
    _lastStatus = value;
    unawaited(_bridge.updateStatus(value));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateStatus);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'mac_radio_kr',
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
    theme: const CupertinoThemeData(
      primaryColor: Color(0xFF007AFF),
      scaffoldBackgroundColor: Color(0x00000000),
    ),
    home: RadioPopover(controller: widget.controller, bridge: _bridge),
  );
}

class RadioPopover extends StatelessWidget {
  const RadioPopover({
    super.key,
    required this.controller,
    required this.bridge,
  });

  final RadioController controller;
  final MenuBarBridge bridge;

  Future<void> _chooseChannel() async {
    final id = await bridge.showChannels(controller.channel.id);
    if (id != null) await controller.select(RadioChannel.byId(id));
  }

  Future<void> _showActions() async {
    if (await bridge.showActions() == 'quit') {
      await controller.shutdown();
      await bridge.quit();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
      final text = CupertinoDynamicColor.resolve(
        CupertinoColors.label,
        context,
      );
      final secondary = CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      );
      final busy = controller.status == RadioStatus.connecting;
      final active = controller.status == RadioStatus.playing;

      return ColoredBox(
        color: const Color(0x00000000),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ChannelArtwork(channel: controller.channel, dark: dark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PanelButton(
                            label: '채널 선택',
                            onPressed: _chooseChannel,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    controller.channel.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  CupertinoIcons.chevron_down,
                                  size: 10,
                                  color: secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _PanelButton(
                          label: '더보기',
                          onPressed: _showActions,
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            size: 16,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (active) ...[
                          const _LiveBadge(),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            controller.status == RadioStatus.failed
                                ? '연결 실패 · 재생을 눌러 다시 시도'
                                : controller.status.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: controller.status == RadioStatus.failed
                                  ? CupertinoColors.systemRed
                                  : secondary,
                              fontSize: 11,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PanelButton(
                          label: '이전 채널',
                          onPressed: () => controller.step(-1),
                          child: Icon(
                            CupertinoIcons.backward_end_fill,
                            size: 24,
                            color: secondary,
                          ),
                        ),
                        _PanelButton(
                          label: busy || active ? '재생 정지' : '라디오 재생',
                          onPressed: controller.togglePlayback,
                          child: SizedBox(
                            width: 40,
                            height: 36,
                            child: Center(
                              child: busy
                                  ? const CupertinoActivityIndicator(radius: 10)
                                  : Icon(
                                      active
                                          ? CupertinoIcons.stop_fill
                                          : CupertinoIcons.play_fill,
                                      size: active ? 24 : 30,
                                      color: text,
                                    ),
                            ),
                          ),
                        ),
                        _PanelButton(
                          label: '다음 채널',
                          onPressed: () => controller.step(1),
                          child: Icon(
                            CupertinoIcons.forward_end_fill,
                            size: 24,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.speaker_fill,
                          size: 13,
                          color: secondary,
                        ),
                        Expanded(
                          child: Semantics(
                            label: '볼륨',
                            value: '${(controller.volume * 100).round()}%',
                            child: SizedBox(
                              height: 28,
                              child: Material(
                                type: MaterialType.transparency,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    activeTrackColor: const Color(0xFF007AFF),
                                    inactiveTrackColor: secondary.withValues(
                                      alpha: 0.22,
                                    ),
                                    thumbColor: dark
                                        ? const Color(0xFFE2E2E6)
                                        : CupertinoColors.white,
                                    overlayColor: const Color(0x19007AFF),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5,
                                      elevation: 1,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 9,
                                    ),
                                    showValueIndicator:
                                        ShowValueIndicator.never,
                                  ),
                                  child: Slider(
                                    value: controller.volume,
                                    onChanged: controller.setVolume,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    semanticFormatterCallback: (value) =>
                                        '${(value * 100).round()}%',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.speaker_3_fill,
                          size: 16,
                          color: secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChannelArtwork extends StatelessWidget {
  const _ChannelArtwork({required this.channel, required this.dark});

  final RadioChannel channel;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = switch (channel.station) {
      'KBS' => const Color(0xFF2563EB),
      'MBC' => const Color(0xFF7456BB),
      'SBS' => const Color(0xFF0891B2),
      'CBS' => const Color(0xFF158778),
      _ => const Color(0xFFD18A24),
    };
    return Semantics(
      label: '${channel.station} 라디오',
      image: true,
      child: Container(
        width: 92,
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(
                alpha: dark ? 0.18 : 0.10,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.antenna_radiowaves_left_right,
              size: 28,
              color: CupertinoColors.white,
            ),
            const SizedBox(height: 8),
            Text(
              channel.station,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'RADIO',
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.75),
                fontSize: 8,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: CupertinoColors.systemRed.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(3),
    ),
    child: const Text(
      'LIVE',
      style: TextStyle(
        color: CupertinoColors.systemRed,
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

class _PanelButton extends StatefulWidget {
  const _PanelButton({
    required this.label,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.all(4),
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final EdgeInsets padding;

  @override
  State<_PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<_PanelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        label: widget.label,
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _hovered
                ? CupertinoDynamicColor.resolve(
                    CupertinoColors.label,
                    context,
                  ).withValues(alpha: 0.06)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(5),
          ),
          child: CupertinoButton(
            padding: widget.padding,
            minimumSize: Size.zero,
            onPressed: widget.onPressed,
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}
