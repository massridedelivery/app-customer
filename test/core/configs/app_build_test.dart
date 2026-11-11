import 'package:customer_app/core/configs/app_build.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version and build join as <version>+<build>', () {
    expect(AppBuild.format('1.0.5', '129'), '1.0.5+129');
    expect(AppBuild.format(' 1.0.5 ', ' 129 '), '1.0.5+129');
    expect(AppBuild.format('1.0.5', ''), '1.0.5');
  });

  test('a value the backend would drop is not sent', () {
    expect(AppBuild.format('1.0.5', 'ข'), '');
    expect(AppBuild.format('1.0 5', '1'), '');
    expect(AppBuild.format('1.${'0' * 70}', '1'), '');
    expect(AppBuild.format('', ''), '');
  });

  test('no X-App-Version before the build is read', () {
    AppBuild.debugVersion = '';
    expect(AppBuild.headers.containsKey('X-App-Version'), isFalse);
    expect(AppBuild.headers['X-App-Platform'], 'android');
    AppBuild.debugVersion = '1.0.5+129';
    addTearDown(() => AppBuild.debugVersion = '');
    expect(AppBuild.headers['X-App-Version'], '1.0.5+129');
  });
}
