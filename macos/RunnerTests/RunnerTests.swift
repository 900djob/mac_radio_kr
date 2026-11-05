import Cocoa
import FlutterMacOS
import XCTest
@testable import mac_radio_kr

class RunnerTests: XCTestCase {

  private final class MenuTarget: NSObject {
    @objc func select(_ sender: NSMenuItem) {}
  }

  func testChannelMenuGroupsByRegionAndBroadcasterAndMarksSelection() {
    let target = MenuTarget()
    let menu = AppDelegate.buildChannelMenu(
      channels: [
        ["id": "kbs_1", "name": "KBS 1라디오", "station": "KBS", "region": "전국"],
        ["id": "kbs_2", "name": "KBS 2라디오", "station": "KBS", "region": "전국"],
        ["id": "bbs_busan", "name": "BBS 부산불교방송", "station": "BBS", "region": "부산"],
      ],
      selectedId: "kbs_2",
      target: target,
      action: #selector(MenuTarget.select(_:)))

    XCTAssertEqual(menu.items.map(\.title), ["전국", "부산"])
    let kbsMenu = menu.items[0].submenu?.items.first { $0.title == "KBS" }?.submenu
    XCTAssertEqual(kbsMenu?.items.map(\.title), ["KBS 1라디오", "KBS 2라디오"])
    XCTAssertEqual(kbsMenu?.items[1].state, .on)
    XCTAssertEqual(menu.items[1].submenu?.items.first?.title, "BBS")
  }

}
