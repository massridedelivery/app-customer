/// Opens the app's WebSocket channel, picking the implementation that can
/// actually keep it alive on the current platform.
///
/// The web build must never see `dart:io`, hence the conditional export.
library;

export 'socket_channel_factory_web.dart'
    if (dart.library.io) 'socket_channel_factory_io.dart';
