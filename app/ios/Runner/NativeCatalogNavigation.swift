import Flutter
import UIKit

private enum CatalogNavigationKind: String {
  case top
  case bottom
}

final class NativeCatalogNavigationFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NativeCatalogNavigationView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args as? [String: Any],
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class NativeCatalogNavigationView: NSObject, FlutterPlatformView,
  UITabBarDelegate
{
  private let container: UIView
  private let channel: FlutterMethodChannel
  private var arguments: [String: Any]
  private var navigationBar: UINavigationBar?
  private var navigationItem: UINavigationItem?
  private var tabBar: UITabBar?

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear
    self.arguments = arguments ?? [:]
    channel = FlutterMethodChannel(
      name: "world.roco.handbook/catalog_navigation/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update", let updated = call.arguments as? [String: Any]
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.arguments = updated
      self?.applyArguments()
      result(nil)
    }

    buildNavigation()
    applyArguments()
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    container
  }

  private var kind: CatalogNavigationKind {
    CatalogNavigationKind(rawValue: arguments["kind"] as? String ?? "top") ?? .top
  }

  private func buildNavigation() {
    switch kind {
    case .top:
      let bar = UINavigationBar(frame: container.bounds)
      bar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      bar.isTranslucent = true
      bar.backgroundColor = .clear
      let item = UINavigationItem()
      bar.items = [item]
      container.addSubview(bar)
      navigationBar = bar
      navigationItem = item
      configureFallbackAppearance(for: bar)
    case .bottom:
      let bar = UITabBar(frame: container.bounds)
      bar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      bar.isTranslucent = true
      bar.backgroundColor = .clear
      bar.delegate = self
      bar.itemPositioning = .fill
      bar.accessibilityElementsHidden = true
      container.addSubview(bar)
      tabBar = bar
      configureFallbackAppearance(for: bar)
    }
  }

  private func configureFallbackAppearance(for navigationBar: UINavigationBar) {
    guard #unavailable(iOS 26.0) else { return }
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
    navigationBar.standardAppearance = appearance
    navigationBar.scrollEdgeAppearance = appearance
    navigationBar.compactAppearance = appearance
  }

  private func configureFallbackAppearance(for tabBar: UITabBar) {
    guard #unavailable(iOS 26.0) else { return }
    let appearance = UITabBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
    tabBar.standardAppearance = appearance
    tabBar.scrollEdgeAppearance = appearance
  }

  private func applyArguments() {
    overrideInterfaceStyle()
    switch kind {
    case .top:
      updateTopNavigation()
    case .bottom:
      updateBottomNavigation()
    }
  }

  private func overrideInterfaceStyle() {
    container.overrideUserInterfaceStyle = arguments["brightness"] as? String == "dark"
      ? .dark : .light
  }

  private func updateTopNavigation() {
    guard let item = navigationItem else { return }
    item.title = arguments["title"] as? String

    if arguments["showsBackButton"] as? Bool == true {
      let back = UIBarButtonItem(
        image: UIImage(systemName: "chevron.backward"),
        style: .plain,
        target: self,
        action: #selector(handleBack)
      )
      back.accessibilityLabel = arguments["backAccessibilityLabel"] as? String
      item.leftBarButtonItem = back
    } else {
      item.leftBarButtonItem = nil
    }

    guard let dataVersion = arguments["dataVersionLabel"] as? String else {
      item.rightBarButtonItems = nil
      return
    }
    let information = UIBarButtonItem(
      image: UIImage(systemName: "info.circle"),
      style: .plain,
      target: self,
      action: #selector(handleShowInformation)
    )
    information.accessibilityLabel = arguments["informationAccessibilityLabel"] as? String
    let version = UIBarButtonItem(
      title: dataVersion,
      style: .plain,
      target: self,
      action: #selector(handleShowInformation)
    )
    version.accessibilityLabel = arguments["informationAccessibilityLabel"] as? String
    item.rightBarButtonItems = [information, version]
  }

  private func updateBottomNavigation() {
    guard let bar = tabBar else { return }
    let labels = arguments["labels"] as? [String] ?? []
    guard labels.count == 4 else { return }

    let symbols = [
      ("pawprint", "pawprint.fill"),
      ("sparkles", "sparkles"),
      ("square.grid.2x2", "square.grid.2x2.fill"),
      ("gearshape", "gearshape.fill"),
    ]
    let items = zip(labels, symbols).map { label, symbol in
      UITabBarItem(
        title: label,
        image: UIImage(systemName: symbol.0),
        selectedImage: UIImage(systemName: symbol.1)
      )
    }
    bar.items = items
    let selectedIndex = min(max(arguments["selectedIndex"] as? Int ?? 0, 0), items.count - 1)
    bar.selectedItem = items[selectedIndex]
  }

  @objc private func handleBack() {
    channel.invokeMethod("back", arguments: nil)
  }

  @objc private func handleShowInformation() {
    channel.invokeMethod("showInformation", arguments: nil)
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    guard let index = tabBar.items?.firstIndex(of: item) else { return }
    channel.invokeMethod("destinationSelected", arguments: index)
  }
}
