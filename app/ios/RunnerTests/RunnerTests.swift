import XCTest

final class RunnerTests: XCTestCase {

  func testAppIdentityUsesPublishedValues() {
    XCTAssertEqual(
      Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
      "洛克王国：世界图鉴"
    )
    XCTAssertEqual(Bundle.main.bundleIdentifier, "world.roco.rocoHandbook")
  }
}
