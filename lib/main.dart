import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mgr_settings_gui/screens/config_screen.dart' as conf;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Size configScreenSize = Size(800, 600);
Menu contextMenu = Menu();
final GlobalKey<conf.ConfigScreenState> configKey =
    GlobalKey<conf.ConfigScreenState>();
SystemTray systemTray = SystemTray();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Starting application debug/sample/standalone application...');
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManagerPlus.ensureInitialized(
    int.parse(args.lastOrNull ?? '0'),
  ).then((_) async {
    Map<String, dynamic> jsonArgs = jsonDecode(args.firstOrNull ?? '{}');
    switch (jsonArgs['WindowName']) {
      case null || '': // initial startup
        runApp(
          mainApp, // Program entrypoint.
        );
        log('mainapp received window id: ${WindowManagerPlus.current.id}');
      case 'Settings':
        double width = double.parse(jsonArgs['Size']['width']);
        double height = double.parse(jsonArgs['Size']['height']);
        Size size = Size(width, height);
        WindowManagerPlus.current.setSize(size);
        runApp(configApp);
        log('configapp received window id: ${WindowManagerPlus.current.id}');
      default:
        log('Unsupported argument: ${args.firstOrNull}');
        runApp(
          const ContentDialog(
            title: Text('Error'),
            content: Text('Unsupported argument'),
          ),
        );
    }
  });
  await systemTray.initSystemTray(
    title: "system tray",
    iconPath: 'assets/app_icon.ico',
  );
  systemTray.registerSystemTrayEventHandler((eventName) {
    if (eventName.contains(kSystemTrayEventRightClick)) {
      systemTray.popUpContextMenu();
    }
    systemTray.setContextMenu(contextMenu);
    contextMenu.buildFrom([settingsMenu, exitMenu]);
  });
}

MenuItemBase settingsMenu = MenuItemLabel(
  label: 'Settings',
  onClicked: (_) async {
    WindowManagerPlus? createWindow = await WindowManagerPlus.createWindow([
      jsonEncode(
        {
              'WindowName': 'Settings',
              'Size': {
                'height': configScreenSize.height,
                'width': configScreenSize.width,
              },
            }
      ),
    ]);
    if (createWindow == null)
      log('Window creation has failed, mossnerg suger!');
  },
);
MenuItemBase exitMenu = MenuItemLabel(label: 'Exit', onClicked: (_) => exit(1));

FluentApp get configApp => FluentApp(
  title: 'Inställningar',
  home: conf.ConfigScreen(
    windowOptions: WindowOptions(),
    windowID: WindowManagerPlus.current.id,
    key: configKey,
  ),
);

FluentApp mainApp = FluentApp(
  title: 'Swish App',
  home: StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: ProgressRing());
      }
      if (snapshot.hasData) {
        return MainScreen(user: snapshot.data!);
      } else {
        return LoginScreen(onSuccess: (user) {});
      }
    },
  ),
  debugShowCheckedModeBanner: false,
);
