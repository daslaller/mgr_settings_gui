import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../screens/config_screen.dart';

final GlobalKey<ConfigScreenState> configKey =
GlobalKey<ConfigScreenState>();

WindowOptions configScreenWindowOptions = WindowOptions(
  center: true,
  size: Size(800, 600),
  skipTaskbar: true,
  windowButtonVisibility: false,
  titleBarStyle: TitleBarStyle.hidden,
);

FluentApp get configApp => FluentApp(
  title: 'Inställningar',
  home: ConfigScreen(
    windowOptions: WindowOptions(),
    windowID: WindowManagerPlus.current.id,
    key: configKey,
    window: WindowManagerPlus.current,
  )..init(),
);
