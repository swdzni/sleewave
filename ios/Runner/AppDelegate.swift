import Flutter
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var remoteControlsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "sleewave/link_opener",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "openUrl",
            let urlString = call.arguments as? String,
            let url = URL(string: urlString) else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.open(url) { opened in
        result(opened)
      }
    }

    let remoteControlsChannel = FlutterMethodChannel(
      name: "sleewave/remote_controls",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    self.remoteControlsChannel = remoteControlsChannel
    remoteControlsChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "configure" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.configureRemoteControls()
      result(nil)
    }
  }

  private func configureRemoteControls() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.nextTrackCommand.removeTarget(nil)
    commandCenter.previousTrackCommand.removeTarget(nil)
    commandCenter.seekForwardCommand.removeTarget(nil)
    commandCenter.seekBackwardCommand.removeTarget(nil)

    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.isEnabled = true
    commandCenter.seekForwardCommand.isEnabled = true
    commandCenter.seekBackwardCommand.isEnabled = true

    commandCenter.nextTrackCommand.addTarget(self, action: #selector(remoteNext(_:)))
    commandCenter.previousTrackCommand.addTarget(self, action: #selector(remotePrevious(_:)))
    commandCenter.seekForwardCommand.addTarget(self, action: #selector(remoteSeekForward(_:)))
    commandCenter.seekBackwardCommand.addTarget(self, action: #selector(remoteSeekBackward(_:)))
  }

  @objc private func remoteNext(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    remoteControlsChannel?.invokeMethod("next", arguments: nil)
    return .success
  }

  @objc private func remotePrevious(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    remoteControlsChannel?.invokeMethod("previous", arguments: nil)
    return .success
  }

  @objc private func remoteSeekForward(_ event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
    remoteControlsChannel?.invokeMethod(
      event.type == .beginSeeking ? "seekForwardBegin" : "seekForwardEnd",
      arguments: nil
    )
    return .success
  }

  @objc private func remoteSeekBackward(_ event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
    remoteControlsChannel?.invokeMethod(
      event.type == .beginSeeking ? "seekBackwardBegin" : "seekBackwardEnd",
      arguments: nil
    )
    return .success
  }
}
