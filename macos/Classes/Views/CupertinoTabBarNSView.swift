import FlutterMacOS
import Cocoa

class CupertinoTabBarNSView: NSView {
  private let channel: FlutterMethodChannel
  private let control: NSSegmentedControl
  private var currentLabels: [String] = []
  private var currentSymbols: [String] = []
  private var currentHasCustomIcon: [Bool] = []
  private var currentCustomIconImages: [NSImage?] = []
  private var currentSizes: [NSNumber] = []
  private var currentSelectedIndex: Int = 0
  private var currentTint: NSColor? = nil
  private var currentBackground: NSColor? = nil

  init(viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "CupertinoNativeTabBar_\(viewId)", binaryMessenger: messenger)
    self.control = NSSegmentedControl(labels: [], trackingMode: .selectOne, target: nil, action: nil)

    var labels: [String] = []
    var symbols: [String] = []
    var sizes: [NSNumber] = []
    var hasCustomIcon: [Bool] = []
    var selectedIndex: Int = 0
    var isDark: Bool = false
    var tint: NSColor? = nil
    var bg: NSColor? = nil

    if let dict = args as? [String: Any] {
      labels = (dict["labels"] as? [String]) ?? []
      symbols = (dict["sfSymbols"] as? [String]) ?? []
      sizes = (dict["sfSymbolSizes"] as? [NSNumber]) ?? []
      hasCustomIcon = (dict["hasCustomIcon"] as? [Bool]) ?? []
      if let v = dict["selectedIndex"] as? NSNumber { selectedIndex = v.intValue }
      if let v = dict["isDark"] as? NSNumber { isDark = v.boolValue }
      if let style = dict["style"] as? [String: Any] {
        if let n = style["tint"] as? NSNumber { tint = Self.colorFromARGB(n.intValue) }
        if let n = style["backgroundColor"] as? NSNumber { bg = Self.colorFromARGB(n.intValue) }
      }
    }

    super.init(frame: .zero)

    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
    appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)

    // Initialize custom icon images array
    let count = max(labels.count, symbols.count, hasCustomIcon.count)
    let customIconImages: [NSImage?] = Array(repeating: nil, count: count)

    configureSegments(labels: labels, symbols: symbols, sizes: sizes, customIconImages: customIconImages)
    if selectedIndex >= 0 { control.selectedSegment = selectedIndex }
    // Save current style and content for retinting
    self.currentLabels = labels
    self.currentSymbols = symbols
    self.currentHasCustomIcon = hasCustomIcon
    self.currentCustomIconImages = customIconImages
    self.currentSizes = sizes
    self.currentSelectedIndex = selectedIndex
    self.currentTint = tint
    self.currentBackground = bg
    if let b = bg { wantsLayer = true; layer?.backgroundColor = b.cgColor }
    applySegmentTint()

    control.target = self
    control.action = #selector(onChanged(_:))

    addSubview(control)
    control.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      control.leadingAnchor.constraint(equalTo: leadingAnchor),
      control.trailingAnchor.constraint(equalTo: trailingAnchor),
      control.topAnchor.constraint(equalTo: topAnchor),
      control.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "getIntrinsicSize":
        let size = self.control.intrinsicContentSize
        result(["width": Double(size.width), "height": Double(size.height)])
      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any], let idx = (args["index"] as? NSNumber)?.intValue {
          self.currentSelectedIndex = idx
          self.control.selectedSegment = idx
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing index", details: nil)) }
      case "setItems":
        if let args = call.arguments as? [String: Any] {
          let labels = (args["labels"] as? [String]) ?? []
          let symbols = (args["sfSymbols"] as? [String]) ?? []
          let sizes = (args["sfSymbolSizes"] as? [NSNumber]) ?? []
          let hasCustomIcon = (args["hasCustomIcon"] as? [Bool]) ?? []
          let selectedIndex = (args["selectedIndex"] as? NSNumber)?.intValue ?? 0
          self.currentLabels = labels
          self.currentSymbols = symbols
          self.currentSizes = sizes
          self.currentHasCustomIcon = hasCustomIcon
          self.currentSelectedIndex = selectedIndex
          // Resize custom icon images array if needed
          let count = max(labels.count, symbols.count, hasCustomIcon.count)
          while self.currentCustomIconImages.count < count {
            self.currentCustomIconImages.append(nil)
          }
          self.configureSegments(labels: labels, symbols: symbols, sizes: sizes, customIconImages: self.currentCustomIconImages)
          if selectedIndex >= 0 { self.control.selectedSegment = selectedIndex }
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing items", details: nil)) }
      case "setCustomIconImages":
        if let args = call.arguments as? [String: Any], let images = args["images"] as? [Any?] {
          self.currentCustomIconImages = images.map { item -> NSImage? in
            guard let data = item as? FlutterStandardTypedData else { return nil }
            guard let image = NSImage(data: data.data) else { return nil }
            // Scale down the image (rendered at 2x for retina)
            let scaledSize = NSSize(width: image.size.width / 2.0, height: image.size.height / 2.0)
            let scaledImage = NSImage(size: scaledSize)
            scaledImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: scaledSize))
            scaledImage.unlockFocus()
            scaledImage.isTemplate = true
            return scaledImage
          }
          // Rebuild segments with new images, preserving selection
          self.configureSegments(labels: self.currentLabels, symbols: self.currentSymbols, sizes: self.currentSizes, customIconImages: self.currentCustomIconImages)
          if self.currentSelectedIndex >= 0 { self.control.selectedSegment = self.currentSelectedIndex }
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing images", details: nil)) }
      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let n = args["tint"] as? NSNumber { self.currentTint = Self.colorFromARGB(n.intValue) }
          if let n = args["backgroundColor"] as? NSNumber {
            let c = Self.colorFromARGB(n.intValue)
            self.currentBackground = c
            self.wantsLayer = true
            self.layer?.backgroundColor = c.cgColor
          }
          self.applySegmentTint()
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing style", details: nil)) }
      case "setBrightness":
        if let args = call.arguments as? [String: Any], let isDark = (args["isDark"] as? NSNumber)?.boolValue {
          self.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
          result(nil)
        } else { result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil)) }
      case "setLayout":
        // macOS doesn't support split layout, just acknowledge the call
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  required init?(coder: NSCoder) { return nil }

  private func configureSegments(labels: [String], symbols: [String], sizes: [NSNumber], customIconImages: [NSImage?] = []) {
    let count = max(labels.count, symbols.count, customIconImages.count)
    control.segmentCount = count
    for i in 0..<count {
      var image: NSImage? = nil
      // First try SF Symbol
      if i < symbols.count && !symbols[i].isEmpty, #available(macOS 11.0, *) {
        image = NSImage(systemSymbolName: symbols[i], accessibilityDescription: nil)
        if var img = image, i < sizes.count, #available(macOS 12.0, *) {
          let size = CGFloat(truncating: sizes[i])
          let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
          image = img.withSymbolConfiguration(cfg) ?? img
        }
      }
      // Then try custom icon image if available
      if image == nil, i < customIconImages.count, let customImage = customIconImages[i] {
        image = customImage
        image?.isTemplate = true
      }
      if let img = image {
        control.setImage(img, forSegment: i)
      } else if i < labels.count {
        control.setLabel(labels[i], forSegment: i)
      } else {
        control.setLabel("", forSegment: i)
      }
    }
  }

  private func applySegmentTint() {
    let count = control.segmentCount
    guard count > 0 else { return }
    let sel = control.selectedSegment
    for i in 0..<count {
      var image: NSImage? = nil
      // First try SF Symbol
      if let name = (i < currentSymbols.count ? currentSymbols[i] : nil), !name.isEmpty,
         #available(macOS 11.0, *) {
        image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        if var img = image, i < currentSizes.count, #available(macOS 12.0, *) {
          let size = CGFloat(truncating: currentSizes[i])
          let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
          image = img.withSymbolConfiguration(cfg) ?? img
        }
        if var img = image, i == sel, let tint = currentTint {
          if #available(macOS 12.0, *) {
            let cfg = NSImage.SymbolConfiguration(hierarchicalColor: tint)
            image = img.withSymbolConfiguration(cfg) ?? img
          } else {
            image = img.tinted(with: tint)
          }
        }
      }
      // Then try custom icon image if available
      if image == nil, i < currentCustomIconImages.count, let customImage = currentCustomIconImages[i] {
        image = customImage
        image?.isTemplate = true
        if var img = image, i == sel, let tint = currentTint {
          image = img.tinted(with: tint)
        }
      }
      if let img = image {
        control.setImage(img, forSegment: i)
      }
    }
  }

  private static func colorFromARGB(_ argb: Int) -> NSColor {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
  }

  @objc private func onChanged(_ sender: NSSegmentedControl) {
    channel.invokeMethod("valueChanged", arguments: ["index": sender.selectedSegment])
  }
}

private extension NSImage {
  func tinted(with color: NSColor) -> NSImage {
    let img = NSImage(size: size)
    img.lockFocus()
    let rect = NSRect(origin: .zero, size: size)
    color.set()
    rect.fill()
    draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1.0)
    img.unlockFocus()
    return img
  }
}
