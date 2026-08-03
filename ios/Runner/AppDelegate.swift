import Flutter
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var systemPlayerFavoriteChannel: FlutterMethodChannel?
  private var systemPlayerFavoriteTarget: Any?
  private var systemPlayerFavoriteTrackId: Int?
  private var systemPlayerFavoriteIsPending = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSystemPlayerFavoriteChannel(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
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
  }

  private func handleSystemPlayerFavoriteMethod(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let command = MPRemoteCommandCenter.shared().likeCommand
    switch call.method {
    case "update":
      guard let arguments = call.arguments as? [String: Any],
            let isAvailable = arguments["isAvailable"] as? Bool,
            let isFavorite = arguments["isFavorite"] as? Bool,
            let isPending = arguments["isPending"] as? Bool,
            let localizedTitle = arguments["localizedTitle"] as? String else {
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
      command.localizedTitle = localizedTitle
      command.localizedShortTitle = localizedTitle
      command.isActive = isFavorite
      command.isEnabled = isAvailable
      result(nil)
    case "dispose":
      systemPlayerFavoriteTrackId = nil
      systemPlayerFavoriteIsPending = false
      command.isEnabled = false
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
    let previousIsFavorite = command.isActive
    let shouldBeFavorite = !feedbackEvent.isNegative
    command.isActive = shouldBeFavorite
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
        self.systemPlayerFavoriteIsPending = false
      }
    }

    return .success
  }
}
