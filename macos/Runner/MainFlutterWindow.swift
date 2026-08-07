import Cocoa
import FlutterMacOS
import MediaPlayer

class MainFlutterWindow: NSWindow {
  private var systemPlayerFavoriteChannel: FlutterMethodChannel?
  private var systemPlayerFavoriteTarget: Any?
  private var systemPlayerDislikeTarget: Any?
  private var systemPlayerFavoriteTrackId: Int?
  private var systemPlayerFavoriteIsPending = false

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
    registerSystemPlayerFavoriteChannel(
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    super.awakeFromNib()
  }

  private func setFullscreenEnabled(_ isEnabled: Bool) {
    let isFullscreen = styleMask.contains(.fullScreen)
    if isFullscreen != isEnabled {
      toggleFullScreen(nil)
    }
  }

  private func registerSystemPlayerFavoriteChannel(
    binaryMessenger: FlutterBinaryMessenger
  ) {
    let channel = FlutterMethodChannel(
      name: "esketit_music_app/system_player_favorite",
      binaryMessenger: binaryMessenger
    )
    systemPlayerFavoriteChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleSystemPlayerFavoriteMethod(call, result: result)
    }

    let command = MPRemoteCommandCenter.shared().likeCommand
    if let target = systemPlayerFavoriteTarget {
      command.removeTarget(target)
    }
    systemPlayerFavoriteTarget = command.addTarget { [weak self] event in
      self?.handleSystemPlayerFavoriteCommand(event) ?? .commandFailed
    }
    command.isEnabled = false

    let dislikeCommand = MPRemoteCommandCenter.shared().dislikeCommand
    if let target = systemPlayerDislikeTarget {
      dislikeCommand.removeTarget(target)
    }
    systemPlayerDislikeTarget = dislikeCommand.addTarget { [weak self] event in
      self?.handleSystemPlayerDislikeCommand(event) ?? .commandFailed
    }
    dislikeCommand.isEnabled = false
  }

  private func handleSystemPlayerFavoriteMethod(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let command = MPRemoteCommandCenter.shared().likeCommand
    let dislikeCommand = MPRemoteCommandCenter.shared().dislikeCommand
    switch call.method {
    case "update":
      guard let arguments = call.arguments as? [String: Any],
            let isAvailable = arguments["isAvailable"] as? Bool,
            let isFavorite = arguments["isFavorite"] as? Bool,
            let isDisliked = arguments["isDisliked"] as? Bool,
            let isPending = arguments["isPending"] as? Bool,
            let localizedFavoriteTitle = arguments["localizedFavoriteTitle"] as? String,
            let localizedDislikeTitle = arguments["localizedDislikeTitle"] as? String else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Invalid system player favorite configuration",
            details: nil
          )
        )
        return
      }

      systemPlayerFavoriteTrackId = arguments["trackId"] as? Int
      systemPlayerFavoriteIsPending = isPending
      command.localizedTitle = localizedFavoriteTitle
      command.localizedShortTitle = localizedFavoriteTitle
      command.isActive = isFavorite
      command.isEnabled = isAvailable
      dislikeCommand.localizedTitle = localizedDislikeTitle
      dislikeCommand.localizedShortTitle = localizedDislikeTitle
      dislikeCommand.isActive = isDisliked
      dislikeCommand.isEnabled = isAvailable
      result(nil)
    case "dispose":
      systemPlayerFavoriteTrackId = nil
      systemPlayerFavoriteIsPending = false
      command.isEnabled = false
      dislikeCommand.isEnabled = false
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSystemPlayerFavoriteCommand(
    _ event: MPRemoteCommandEvent
  ) -> MPRemoteCommandHandlerStatus {
    guard let feedbackEvent = event as? MPFeedbackCommandEvent,
          let trackId = systemPlayerFavoriteTrackId,
          !systemPlayerFavoriteIsPending,
          let channel = systemPlayerFavoriteChannel else {
      return .commandFailed
    }

    let command = MPRemoteCommandCenter.shared().likeCommand
    let dislikeCommand = MPRemoteCommandCenter.shared().dislikeCommand
    let previousIsFavorite = command.isActive
    let previousIsDisliked = dislikeCommand.isActive
    let shouldBeFavorite = !feedbackEvent.isNegative
    command.isActive = shouldBeFavorite
    if shouldBeFavorite {
      dislikeCommand.isActive = false
    }
    systemPlayerFavoriteIsPending = true

    channel.invokeMethod(
      "favoriteChanged",
      arguments: [
        "trackId": trackId,
        "shouldBeFavorite": shouldBeFavorite,
      ]
    ) { [weak self] response in
      guard let self else { return }
      let accepted = response as? Bool ?? false
      if !accepted {
        command.isActive = previousIsFavorite
        dislikeCommand.isActive = previousIsDisliked
        self.systemPlayerFavoriteIsPending = false
      }
    }

    return .success
  }

  private func handleSystemPlayerDislikeCommand(
    _ event: MPRemoteCommandEvent
  ) -> MPRemoteCommandHandlerStatus {
    guard let feedbackEvent = event as? MPFeedbackCommandEvent,
          let trackId = systemPlayerFavoriteTrackId,
          !systemPlayerFavoriteIsPending,
          let channel = systemPlayerFavoriteChannel else {
      return .commandFailed
    }

    let favoriteCommand = MPRemoteCommandCenter.shared().likeCommand
    let command = MPRemoteCommandCenter.shared().dislikeCommand
    let previousIsFavorite = favoriteCommand.isActive
    let previousIsDisliked = command.isActive
    let shouldBeDisliked = !feedbackEvent.isNegative
    command.isActive = shouldBeDisliked
    if shouldBeDisliked {
      favoriteCommand.isActive = false
    }
    systemPlayerFavoriteIsPending = true

    channel.invokeMethod(
      "dislikeChanged",
      arguments: [
        "trackId": trackId,
        "shouldBeDisliked": shouldBeDisliked,
      ]
    ) { [weak self] response in
      guard let self else { return }
      let accepted = response as? Bool ?? false
      if !accepted {
        favoriteCommand.isActive = previousIsFavorite
        command.isActive = previousIsDisliked
        self.systemPlayerFavoriteIsPending = false
      }
    }

    return .success
  }
}
