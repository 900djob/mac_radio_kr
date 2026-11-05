import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Tooltip, DefaultMaterialLocalizations;
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PanelButton(
                      label: '${controller.channel.name} · 채널 선택',
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
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 9,
                            color: secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: controller.status == RadioStatus.failed
                        ? '연결 실패 · 재생을 눌러 다시 시도'
                        : controller.status.label,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          const _LiveBadge(),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          controller.status.label,
                          style: TextStyle(
                            color: controller.status == RadioStatus.failed
                                ? CupertinoColors.systemRed
                                : secondary,
                            fontSize: 10,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _PanelButton(
                    label: '더보기',
                    onPressed: _showActions,
                    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                    child: Icon(
                      CupertinoIcons.ellipsis,
                      size: 16,
                      color: secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    _ChannelArtwork(channel: controller.channel, dark: dark),
                    Expanded(
                      child: Center(
                        child: _PanelButton(
                          label: busy || active ? '재생 정지' : '라디오 재생',
                          onPressed: controller.togglePlayback,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: busy
                                  ? const CupertinoActivityIndicator(radius: 12)
                                  : Icon(
                                      active
                                          ? CupertinoIcons.stop_fill
                                          : CupertinoIcons.play_fill,
                                      size: active ? 26 : 32,
                                      color: text,
                                    ),
                            ),
                          ),
                        ),
                      ),
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
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
              size: 22,
              color: CupertinoColors.white,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                channel.station,
                maxLines: 1,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'RADIO',
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.75),
                fontSize: 7,
                letterSpacing: 2,
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
