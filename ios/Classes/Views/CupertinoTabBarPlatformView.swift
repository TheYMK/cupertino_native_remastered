import Flutter
import UIKit

class CupertinoTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let channel: FlutterMethodChannel
  private let container: UIView
  private var tabBar: UITabBar?
  private var tabBarLeft: UITabBar?
  private var tabBarRight: UITabBar?
  private var isSplit: Bool = false
  private var rightCountVal: Int = 1
  private var currentLabels: [String] = []
  private var currentSymbols: [String] = []
  private var currentHasCustomIcon: [Bool] = []
  private var currentCustomIconImages: [UIImage?] = []
  private var currentSelectedIndex: Int = 0
  private var leftInsetVal: CGFloat = 0
  private var rightInsetVal: CGFloat = 0
  private var splitSpacingVal: CGFloat = 8

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar?) {
    self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
    self.container = UIView(frame: frame)

    var labels: [String] = []
    var symbols: [String] = []
    var sizes: [NSNumber] = [] // ignored; use system metrics
    var colors: [NSNumber] = [] // ignored; use tintColor
    var hasCustomIcon: [Bool] = []
    var selectedIndex: Int = 0
    var isDark: Bool = false
    var tint: UIColor? = nil
    var bg: UIColor? = nil
    var split: Bool = false
    var rightCount: Int = 1
    var leftInset: CGFloat = 0
    var rightInset: CGFloat = 0

    if let dict = args as? [String: Any] {
      labels = (dict["labels"] as? [String]) ?? []
      symbols = (dict["sfSymbols"] as? [String]) ?? []
      sizes = (dict["sfSymbolSizes"] as? [NSNumber]) ?? []
      colors = (dict["sfSymbolColors"] as? [NSNumber]) ?? []
      hasCustomIcon = (dict["hasCustomIcon"] as? [Bool]) ?? []
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any] {
        if let n = style["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
        if let n = style["backgroundColor"] as? NSNumber { bg = Self.colorFromARGB(n.intValue) }
      }
      if let s = dict["split"] as? NSNumber { split = s.boolValue }
      if let rc = dict["rightCount"] as? NSNumber { rightCount = rc.intValue }
      if let sp = dict["splitSpacing"] as? NSNumber { splitSpacingVal = CGFloat(truncating: sp) }
      // content insets controlled by Flutter padding; keep zero here
    }

    super.init()

    container.backgroundColor = .clear
    if #available(iOS 13.0, *) { container.overrideUserInterfaceStyle = isDark ? .dark : .light }

    let appearance: UITabBarAppearance? = {
    if #available(iOS 13.0, *) { let ap = UITabBarAppearance(); ap.configureWithDefaultBackground(); return ap }
    return nil
  }()
    // Initialize custom icon images array with placeholders
    let customIconImages: [UIImage?] = Array(repeating: nil, count: max(labels.count, symbols.count, hasCustomIcon.count))
    func buildItems(_ range: Range<Int>, symbols: [String], customIconImages: [UIImage?]) -> [UITabBarItem] {
      var items: [UITabBarItem] = []
      for i in range {
        var image: UIImage? = nil
        // First try SF Symbol
        if i < symbols.count && !symbols[i].isEmpty {
          image = UIImage(systemName: symbols[i])
        }
        // Then try custom icon image if available
        if image == nil, i < customIconImages.count, let customImage = customIconImages[i] {
          image = customImage.withRenderingMode(.alwaysTemplate)
        }
        let title = (i < labels.count) ? labels[i] : nil
        items.append(UITabBarItem(title: title, image: image, selectedImage: image))
      }
      return items
    }
    let count = max(labels.count, symbols.count, hasCustomIcon.count)
    if split && count > rightCount {
      let leftEnd = count - rightCount
      let left = UITabBar(frame: .zero)
      let right = UITabBar(frame: .zero)
      tabBarLeft = left; tabBarRight = right
      left.translatesAutoresizingMaskIntoConstraints = false
      right.translatesAutoresizingMaskIntoConstraints = false
      left.delegate = self; right.delegate = self
      if let bg = bg { left.barTintColor = bg; right.barTintColor = bg }
      if #available(iOS 10.0, *), let tint = tint { left.tintColor = tint; right.tintColor = tint }
      if let ap = appearance { if #available(iOS 13.0, *) { left.standardAppearance = ap; right.standardAppearance = ap } }
      left.items = buildItems(0..<leftEnd, symbols: symbols, customIconImages: customIconImages)
      right.items = buildItems(leftEnd..<count, symbols: symbols, customIconImages: customIconImages)
      if selectedIndex < leftEnd, let items = left.items {
        left.selectedItem = items[selectedIndex]
        right.selectedItem = nil
      } else if let items = right.items {
        let idx = selectedIndex - leftEnd
        if idx >= 0 && idx < items.count { right.selectedItem = items[idx] }
        left.selectedItem = nil
      }
      container.addSubview(left); container.addSubview(right)
      // Compute content-fitting widths for both bars and apply symmetric spacing
      let spacing: CGFloat = splitSpacingVal
      let leftWidth = left.sizeThatFits(.zero).width + leftInset * 2
      let rightWidth = right.sizeThatFits(.zero).width + rightInset * 2
      let total = leftWidth + rightWidth + spacing
      // If total exceeds container, fall back to proportional widths
      if total > container.bounds.width {
        let rightFraction = CGFloat(rightCount) / CGFloat(count)
        NSLayoutConstraint.activate([
          right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -rightInset),
          right.topAnchor.constraint(equalTo: container.topAnchor),
          right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          right.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: rightFraction),
          left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftInset),
          left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -spacing),
          left.topAnchor.constraint(equalTo: container.topAnchor),
          left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
      } else {
        NSLayoutConstraint.activate([
          // Right bar fixed width, pinned to trailing
          right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -rightInset),
          right.topAnchor.constraint(equalTo: container.topAnchor),
          right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          right.widthAnchor.constraint(equalToConstant: rightWidth),
          // Left bar fixed width, pinned to leading
          left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftInset),
          left.topAnchor.constraint(equalTo: container.topAnchor),
          left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          left.widthAnchor.constraint(equalToConstant: leftWidth),
          // Spacing between
          left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -spacing),
        ])
      }
    } else {
      let bar = UITabBar(frame: .zero)
      tabBar = bar
      bar.delegate = self
      bar.translatesAutoresizingMaskIntoConstraints = false
      if let bg = bg { bar.barTintColor = bg }
      if #available(iOS 10.0, *), let tint = tint { bar.tintColor = tint }
      if let ap = appearance { if #available(iOS 13.0, *) { bar.standardAppearance = ap; if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap } } }
      bar.items = buildItems(0..<count, symbols: symbols, customIconImages: customIconImages)
      if selectedIndex >= 0, let items = bar.items, selectedIndex < items.count { bar.selectedItem = items[selectedIndex] }
      container.addSubview(bar)
      NSLayoutConstraint.activate([
        bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        bar.topAnchor.constraint(equalTo: container.topAnchor),
        bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
    }
    // Store split settings for future updates
    self.isSplit = split
    self.rightCountVal = rightCount
    self.currentLabels = labels
    self.currentSymbols = symbols
    self.currentHasCustomIcon = hasCustomIcon
    self.currentCustomIconImages = customIconImages
    self.currentSelectedIndex = selectedIndex
    self.leftInsetVal = leftInset
    self.rightInsetVal = rightInset
channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        if let bar = self.tabBar ?? self.tabBarLeft ?? self.tabBarRight {
          let size = bar.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
          result(["width": Double(size.width), "height": Double(size.height)])
        } else {
          result(["width": Double(self.container.bounds.width), "height": 50.0])
        }
      case "setItems":
        if let args = call.arguments as? [String: Any] {
          let labels = (args["labels"] as? [String]) ?? []
          let symbols = (args["sfSymbols"] as? [String]) ?? []
          let hasCustomIcon = (args["hasCustomIcon"] as? [Bool]) ?? []
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          self.currentLabels = labels
          self.currentSymbols = symbols
          self.currentHasCustomIcon = hasCustomIcon
          self.currentSelectedIndex = selectedIndex
          // Resize custom icon images array if needed, keeping existing images
          let count = max(labels.count, symbols.count, hasCustomIcon.count)
          while self.currentCustomIconImages.count < count {
            self.currentCustomIconImages.append(nil)
          }
          self.rebuildTabBarItems(selectedIndex: selectedIndex)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing items", details: nil)) }
      case "setCustomIconImages":
        if let args = call.arguments as? [String: Any], let images = args["images"] as? [Any?] {
          self.currentCustomIconImages = images.map { item -> UIImage? in
            guard let data = item as? FlutterStandardTypedData else { return nil }
            // Create image with scale factor 2.0 to match retina rendering
            guard let cgImage = UIImage(data: data.data)?.cgImage else { return nil }
            return UIImage(cgImage: cgImage, scale: 2.0, orientation: .up).withRenderingMode(.alwaysTemplate)
          }
          // Rebuild items with the new images, preserving the current selection
          self.rebuildTabBarItems(selectedIndex: self.currentSelectedIndex)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing images", details: nil)) }
      case "setLayout":
        if let args = call.arguments as? [String: Any] {
          let split = (args["split"] as? NSNumber)?.boolValue ?? false
          let rightCount = (args["rightCount"] as? NSNumber)?.intValue ?? 1
          if let sp = args["splitSpacing"] as? NSNumber { self.splitSpacingVal = CGFloat(truncating: sp) }
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          self.isSplit = split
          self.rightCountVal = rightCount
          self.currentSelectedIndex = selectedIndex
          // Rebuild with new layout
          self.rebuildTabBarLayout(selectedIndex: selectedIndex)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing layout", details: nil)) }
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          self.currentSelectedIndex = idx
          // Single bar
          if let bar = self.tabBar, let items = bar.items, idx >= 0, idx < items.count {
            bar.selectedItem = items[idx]
            result(nil)
            return
          }
          // Split bars
          if let left = self.tabBarLeft, let leftItems = left.items {
            if idx < leftItems.count, idx >= 0 {
              left.selectedItem = leftItems[idx]
              self.tabBarRight?.selectedItem = nil
              result(nil)
              return
            }
            if let right = self.tabBarRight, let rightItems = right.items {
              let ridx = idx - leftItems.count
              if ridx >= 0, ridx < rightItems.count {
                right.selectedItem = rightItems[ridx]
                self.tabBarLeft?.selectedItem = nil
                result(nil)
                return
              }
            }
          }
          result(FlutterError(code: "bad_args", message: "Index out of range", details: nil))
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            if let bar = self.tabBar { bar.tintColor = c }
            if let left = self.tabBarLeft { left.tintColor = c }
            if let right = self.tabBarRight { right.tintColor = c }
          }
          if let n = args["backgroundColor"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            if let bar = self.tabBar { bar.barTintColor = c }
            if let left = self.tabBarLeft { left.barTintColor = c }
            if let right = self.tabBarRight { right.barTintColor = c }
          }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          if #available(iOS 13.0, *) { self.container.overrideUserInterfaceStyle = isDark ? .dark : .light }
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    // Single bar case
    if let single = self.tabBar, single === tabBar, let items = single.items, let idx = items.firstIndex(of: item) {
      channel.invokeMethod("valueChanged", arguments: ["index": idx])
      return
    }
    // Split left
    if let left = tabBarLeft, left === tabBar, let items = left.items, let idx = items.firstIndex(of: item) {
      tabBarRight?.selectedItem = nil
      channel.invokeMethod("valueChanged", arguments: ["index": idx])
      return
    }
    // Split right
    if let right = tabBarRight, right === tabBar, let items = right.items, let idx = items.firstIndex(of: item), let left = tabBarLeft, let leftItems = left.items {
      tabBarLeft?.selectedItem = nil
      channel.invokeMethod("valueChanged", arguments: ["index": leftItems.count + idx])
      return
    }
  }

  private static func colorFromARGB(_ argb: Int) -> UIColor {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  /// Builds tab bar items from current state.
  private func buildTabBarItems(_ range: Range<Int>) -> [UITabBarItem] {
    var items: [UITabBarItem] = []
    for i in range {
      var image: UIImage? = nil
      // First try SF Symbol
      if i < currentSymbols.count && !currentSymbols[i].isEmpty {
        image = UIImage(systemName: currentSymbols[i])
      }
      // Then try custom icon image if available
      if image == nil, i < currentCustomIconImages.count, let customImage = currentCustomIconImages[i] {
        image = customImage.withRenderingMode(.alwaysTemplate)
      }
      let title = (i < currentLabels.count) ? currentLabels[i] : nil
      items.append(UITabBarItem(title: title, image: image, selectedImage: image))
    }
    return items
  }

  /// Rebuilds tab bar items without changing layout.
  private func rebuildTabBarItems(selectedIndex: Int?) {
    let count = max(currentLabels.count, currentSymbols.count, currentCustomIconImages.count)
    if isSplit && count > rightCountVal, let left = tabBarLeft, let right = tabBarRight {
      let leftEnd = count - rightCountVal
      left.items = buildTabBarItems(0..<leftEnd)
      right.items = buildTabBarItems(leftEnd..<count)
      if let idx = selectedIndex {
        if idx < leftEnd, let items = left.items, idx >= 0, idx < items.count {
          left.selectedItem = items[idx]
          right.selectedItem = nil
        } else if let items = right.items {
          let ridx = idx - leftEnd
          if ridx >= 0 && ridx < items.count {
            right.selectedItem = items[ridx]
            left.selectedItem = nil
          }
        }
      }
    } else if let bar = tabBar {
      bar.items = buildTabBarItems(0..<count)
      if let idx = selectedIndex, let items = bar.items, idx >= 0, idx < items.count {
        bar.selectedItem = items[idx]
      }
    }
  }

  /// Rebuilds the entire tab bar layout.
  private func rebuildTabBarLayout(selectedIndex: Int) {
    // Remove existing bars
    tabBar?.removeFromSuperview(); tabBar = nil
    tabBarLeft?.removeFromSuperview(); tabBarLeft = nil
    tabBarRight?.removeFromSuperview(); tabBarRight = nil

    let appearance: UITabBarAppearance? = {
      if #available(iOS 13.0, *) { let ap = UITabBarAppearance(); ap.configureWithDefaultBackground(); return ap }
      return nil
    }()

    let count = max(currentLabels.count, currentSymbols.count, currentCustomIconImages.count)
    let leftInset = leftInsetVal
    let rightInset = rightInsetVal

    if isSplit && count > rightCountVal {
      let leftEnd = count - rightCountVal
      let left = UITabBar(frame: .zero)
      let right = UITabBar(frame: .zero)
      tabBarLeft = left; tabBarRight = right
      left.translatesAutoresizingMaskIntoConstraints = false
      right.translatesAutoresizingMaskIntoConstraints = false
      left.delegate = self; right.delegate = self
      if let ap = appearance {
        if #available(iOS 13.0, *) { left.standardAppearance = ap; right.standardAppearance = ap }
      }
      left.items = buildTabBarItems(0..<leftEnd)
      right.items = buildTabBarItems(leftEnd..<count)
      if selectedIndex < leftEnd, let items = left.items, selectedIndex >= 0, selectedIndex < items.count {
        left.selectedItem = items[selectedIndex]
        right.selectedItem = nil
      } else if let items = right.items {
        let idx = selectedIndex - leftEnd
        if idx >= 0 && idx < items.count {
          right.selectedItem = items[idx]
          left.selectedItem = nil
        }
      }
      container.addSubview(left); container.addSubview(right)
      let spacing: CGFloat = splitSpacingVal
      let leftWidth = left.sizeThatFits(.zero).width + leftInset * 2
      let rightWidth = right.sizeThatFits(.zero).width + rightInset * 2
      let total = leftWidth + rightWidth + spacing
      if total > container.bounds.width {
        let rightFraction = CGFloat(rightCountVal) / CGFloat(count)
        NSLayoutConstraint.activate([
          right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -rightInset),
          right.topAnchor.constraint(equalTo: container.topAnchor),
          right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          right.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: rightFraction),
          left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftInset),
          left.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -spacing),
          left.topAnchor.constraint(equalTo: container.topAnchor),
          left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
      } else {
        NSLayoutConstraint.activate([
          right.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -rightInset),
          right.topAnchor.constraint(equalTo: container.topAnchor),
          right.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          right.widthAnchor.constraint(equalToConstant: rightWidth),
          left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leftInset),
          left.topAnchor.constraint(equalTo: container.topAnchor),
          left.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          left.widthAnchor.constraint(equalToConstant: leftWidth),
          left.trailingAnchor.constraint(lessThanOrEqualTo: right.leadingAnchor, constant: -spacing),
        ])
      }
    } else {
      let bar = UITabBar(frame: .zero)
      tabBar = bar
      bar.delegate = self
      bar.translatesAutoresizingMaskIntoConstraints = false
      if let ap = appearance {
        if #available(iOS 13.0, *) {
          bar.standardAppearance = ap
          if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = ap }
        }
      }
      bar.items = buildTabBarItems(0..<count)
      if let items = bar.items, selectedIndex >= 0, selectedIndex < items.count {
        bar.selectedItem = items[selectedIndex]
      }
      container.addSubview(bar)
      NSLayoutConstraint.activate([
        bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        bar.topAnchor.constraint(equalTo: container.topAnchor),
        bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      ])
    }
  }
}
