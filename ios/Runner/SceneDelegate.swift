import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// Shows the engine AppDelegate already started (see its flutterEngine)
  /// instead of letting a storyboard make a second one.
  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
    {
      let window = UIWindow(windowScene: windowScene)
      let flutterViewController = FlutterViewController(
        engine: appDelegate.flutterEngine, nibName: nil, bundle: nil)
      // A controller made with an engine has no launch-screen cover of its
      // own: keep the red splash up until Flutter's first frame.
      flutterViewController.splashScreenView =
        UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view
      window.rootViewController = flutterViewController
      self.window = window
      window.makeKeyAndVisible()
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
