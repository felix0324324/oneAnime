import 'dart:io';

class AppPlatform {
  static const bool isTvOS = bool.fromEnvironment('ONEANIME_TVOS');

  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static bool get isHandheldMobile => Platform.isAndroid || isHandheldIOS;

  static bool get isHandheldIOS => Platform.isIOS && !isTvOS;

  static bool get usesWindowManager => isDesktop;

  static bool get usesTVLayout => isTvOS;
}
