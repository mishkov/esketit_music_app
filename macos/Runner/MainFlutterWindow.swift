import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let fullscreenChannel = FlutterMethodChannel(
      name: "esketit_music_app/fullscreen",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    fullscreenChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }

      switch call.method {
      case "enterFullscreen":
        self.setFullscreenEnabled(true)
        result(nil)
      case "exitFullscreen":
        self.setFullscreenEnabled(false)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  private func setFullscreenEnabled(_ isEnabled: Bool) {
    let isFullscreen = styleMask.contains(.fullScreen)
    if isFullscreen != isEnabled {
      toggleFullScreen(nil)
    }
  }
}
