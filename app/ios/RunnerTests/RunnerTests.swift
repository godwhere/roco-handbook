import XCTest

final class RunnerTests: XCTestCase {

  func testAppIdentityUsesPublishedValues() {
    XCTAssertEqual(
      Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
      "洛克手册"
    )
    XCTAssertEqual(Bundle.main.bundleIdentifier, "world.roco.rocoHandbook")
  }
}
