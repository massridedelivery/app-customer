import AVFoundation
import CallKit
import Flutter
import GoogleMaps
import PushKit
import UIKit
import WebRTC
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  /// Started here rather than by the storyboard so Dart runs on every launch,
  /// including the screenless one iOS makes to deliver a driver's call
  /// (PushKit). SceneDelegate shows it once there is a window.
  lazy var flutterEngine = FlutterEngine(name: "main")

  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""
    GMSServices.provideAPIKey(mapsKey)

    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    registerProximityChannel()

    // CallKit owns the audio session during a call: WebRTC's audio starts
    // when CallKit activates the session (didActivateAudioSession).
    RTCAudioSession.sharedInstance().useManualAudio = true
    RTCAudioSession.sharedInstance().isAudioEnabled = false

    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PushKit

  func pushRegistry(
    _ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType
  ) {
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// A driver's call. iOS requires every VoIP push to be reported to CallKit
  /// right here, or it kills the app and stops delivering them; the Dart side
  /// then checks the call still rings and ends it in CallKit if not.
  func pushRegistry(
    _ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType, completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }
    let p = payload.dictionaryPayload
    let callId = p["call_id"] as? String ?? UUID().uuidString
    let name = (p["caller_name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "ไรเดอร์"
    let ring = Int(p["ring_timeout_sec"] as? String ?? "") ?? (p["ring_timeout_sec"] as? Int) ?? 30

    let data = flutter_callkit_incoming.Data(id: callId, nameCaller: name, handle: name, type: 0)
    data.appName = "Mass Move"
    data.avatar = p["caller_avatar"] as? String ?? ""
    data.duration = ring * 1000
    data.handleType = "generic"
    data.supportsVideo = false
    data.maximumCallGroups = 1
    data.maximumCallsPerCallGroup = 1
    data.supportsDTMF = false
    data.supportsHolding = false
    data.supportsGrouping = false
    data.supportsUngrouping = false
    data.includesCallsInRecents = false
    data.audioSessionMode = "voiceChat"
    data.isShowCallback = false
    data.missedNotificationSubtitle = "สายที่ไม่ได้รับ"
    var extra: [String: Any] = [:]
    for (key, value) in p {
      if let k = key as? String { extra[k] = "\(value)" }
    }
    data.extra = extra as NSDictionary

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }

  // MARK: - CallKit

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {}

  func providerDidReset() {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = false
  }

  // MARK: - Proximity

  /// The call screen turns the screen off against the ear
  /// (CallProximity in call_screen.dart).
  private func registerProximityChannel() {
    let channel = FlutterMethodChannel(
      name: "massmove/call_proximity", binaryMessenger: flutterEngine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "set", let on = call.arguments as? Bool {
        UIDevice.current.isProximityMonitoringEnabled = on
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
