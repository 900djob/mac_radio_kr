import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private var radioEngine: FlutterEngine?
  private var radioViewController: FlutterViewController?
  private var menuChannel: FlutterMethodChannel?
  private var volumeChannel: FlutterEventChannel?
  private let systemVolume = SystemOutputVolume()
  private var statusItem: NSStatusItem?
  private let popover = NSPopover()
  private var escapeMonitor: Any?
  private var menuSelection: String?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    // 패널을 닫아도 엔진과 오디오를 유지한다.
    let engine = FlutterEngine(name: "mac_radio_kr", project: nil, allowHeadlessExecution: true)
    radioEngine = engine
    RegisterGeneratedPlugins(registry: engine)
    let channel = FlutterMethodChannel(
      name: "mac_radio_kr/menu_bar", binaryMessenger: engine.binaryMessenger)
    menuChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    let volumeEvents = FlutterEventChannel(name: "mac_radio_kr/system_volume",
                                           binaryMessenger: engine.binaryMessenger)
    volumeChannel = volumeEvents
    volumeEvents.setStreamHandler(self)
    engine.run(withEntrypoint: nil)

    let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    controller.backgroundColor = .clear
    radioViewController = controller
    let content = RadioPopoverController(flutter: controller)
    popover.contentViewController = content
    popover.contentSize = NSSize(width: 220, height: 148)
    popover.behavior = .transient
    popover.animates = true

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem = item
    if let button = item.button {
      let image = NSImage(systemSymbolName: "dot.radiowaves.left.and.right",
                          accessibilityDescription: "mac_radio_kr")
      image?.isTemplate = true
      button.image = image
      button.toolTip = "mac_radio_kr"
      button.target = self
      button.action = #selector(togglePopover)
    }

    escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if event.keyCode == 53, self?.popover.isShown == true,
         self?.popover.behavior == .transient {
        self?.popover.performClose(nil)
        return nil
      }
      return event
    }
  }

  @objc private func togglePopover() {
    guard let button = statusItem?.button else { return }
    if popover.isShown {
      popover.performClose(nil)
    } else {
      NSApp.activate(ignoringOtherApps: true)
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      popover.contentViewController?.view.window?.makeKey()
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getSystemVolume":
      result(systemVolume.state.dictionary)

    case "setSystemVolume":
      guard let volume = call.arguments as? Double, volume.isFinite else {
        result(FlutterError(code: "invalid_volume", message: "Invalid system volume", details: nil))
        return
      }
      do {
        result(try systemVolume.setVolume(volume).dictionary)
      } catch {
        result(FlutterError(code: "volume_unavailable", message: "System volume is unavailable", details: nil))
      }

    case "showChannelMenu":
      guard let args = call.arguments as? [String: Any],
            let channels = args["channels"] as? [[String: String]],
            let selected = args["selectedId"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Invalid channel menu", details: nil))
        return
      }
      let menu = Self.buildChannelMenu(
        channels: channels,
        selectedId: selected,
        target: self,
        action: #selector(selectMenuItem(_:)))
      result(show(menu))

    case "showActionsMenu":
      let menu = NSMenu()
      let quit = NSMenuItem(title: "mac_radio_kr 종료", action: #selector(selectMenuItem(_:)), keyEquivalent: "")
      quit.target = self
      quit.representedObject = "quit"
      menu.addItem(quit)
      result(show(menu))

    case "updateStatus":
      if let text = call.arguments as? String {
        statusItem?.button?.toolTip = "mac_radio_kr — \(text)"
      }
      result(nil)

    case "quit":
      result(nil)
      DispatchQueue.main.async { NSApp.terminate(nil) }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // NSMenu는 패널 경계 밖으로 펼쳐지며 채널 선택 중 팝오버를 유지한다.
  private func show(_ menu: NSMenu) -> String? {
    menuSelection = nil
    popover.behavior = .applicationDefined
    defer { popover.behavior = .transient }
    menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    return menuSelection
  }

  @objc private func selectMenuItem(_ sender: NSMenuItem) {
    menuSelection = sender.representedObject as? String
  }

  static func buildChannelMenu(
    channels: [[String: String]], selectedId: String, target: AnyObject, action: Selector
  ) -> NSMenu {
    let menu = NSMenu()
    var regionMenus: [String: NSMenu] = [:]
    var stationMenus: [String: [String: NSMenu]] = [:]

    for channel in channels {
      guard let id = channel["id"], let name = channel["name"],
            let station = channel["station"], let region = channel["region"] else { continue }
      if regionMenus[region] == nil {
        let submenu = NSMenu(title: region)
        let item = NSMenuItem(title: region, action: nil, keyEquivalent: "")
        item.submenu = submenu
        menu.addItem(item)
        regionMenus[region] = submenu
        stationMenus[region] = [:]
      }
      if stationMenus[region]?[station] == nil {
        let submenu = NSMenu(title: station)
        let item = NSMenuItem(title: station, action: nil, keyEquivalent: "")
        item.submenu = submenu
        regionMenus[region]?.addItem(item)
        stationMenus[region]?[station] = submenu
      }

      let item = NSMenuItem(title: name, action: action, keyEquivalent: "")
      item.target = target
      item.representedObject = id
      item.state = id == selectedId ? .on : .off
      stationMenus[region]?[station]?.addItem(item)
    }
    return menu
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    systemVolume.startObserving { events($0.dictionary) }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    systemVolume.stopObserving()
    return nil
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    if let monitor = escapeMonitor { NSEvent.removeMonitor(monitor) }
    menuChannel?.setMethodCallHandler(nil)
    volumeChannel?.setStreamHandler(nil)
    systemVolume.stopObserving()
    radioEngine?.shutDownEngine()
  }
}

private final class RadioPopoverController: NSViewController {
  private let flutter: FlutterViewController

  init(flutter: FlutterViewController) {
    self.flutter = flutter
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func loadView() {
    let background = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 220, height: 148))
    background.material = .popover
    background.blendingMode = .behindWindow
    background.state = .active
    view = background
    addChild(flutter)
    flutter.view.frame = background.bounds
    flutter.view.autoresizingMask = [.width, .height]
    background.addSubview(flutter.view)
  }
}
