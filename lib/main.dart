import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mgr_settings_gui/screens/config_screen.dart';
import 'package:mgr_settings_gui/screens/login/login_screen.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'firebase_options.dart';

Size configScreenSize = Size(1280, 768);
Menu contextMenu = Menu();

SystemTray systemTray = SystemTray();

WindowOptions applicationWindowOptions() {
  return WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    size: configScreenSize,
    center: true,
    alwaysOnTop: false,
    fullScreen: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    title: 'MGR Mobilx PBX?',
  );
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Starting application debug/sample/standalone application...');
  WidgetsFlutterBinding.ensureInitialized();
  log('working with args: $args');

  await WindowManagerPlus.ensureInitialized(
    int.parse(args.firstOrNull ?? '0'),
  ).then((_) async {
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
    Future.wait([
      Future.delayed(Duration(), () async {
        runApp(
          Center(
            child: Image(
              image: NetworkImage(
                'https://assets.softr-files.com/applications/6295c80c-d68e-4af5-8b8c-3f3b22af7816/assets/4f0c29eb-89b7-4783-95ba-c06286d03481.png',
              ),
            ),
          ),
        );
      }),
      Future.delayed(Duration(), () async {
        await WindowManagerPlus.current.waitUntilReadyToShow(
          applicationWindowOptions(),
          () async {
            await WindowManagerPlus.current.setAsFrameless();
            await WindowManagerPlus.current.setTitle('MGR Mobilx PBX!');
            await WindowManagerPlus.current.setPreventClose(true);
            await WindowManagerPlus.current.show();
          },
        );
      }),
      Future.delayed(
        Duration(seconds: 2),
        () => runApp(
          mgrPbxApp(), // Program entrypoint.
        ),
      ),
    ]);

    log('mainapp received window id: ${WindowManagerPlus.current.id}');
  });
}

FluentApp mgrPbxApp() {
  return FluentApp(
    title: 'MGR Mobilx PBX',
    theme: FluentThemeData(
      brightness: Brightness.dark,
      accentColor: Colors.purple,
    ),
    initialRoute: '/login',
    routes: {'/login': (context) => constructLoginLogic(ConfigScreen())},
    debugShowCheckedModeBanner: false,
  );
}

MenuItemBase settingsMenu = MenuItemLabel(
  label: 'Visa',
  onClicked: (_) async {
    if (await WindowManagerPlus.current.isVisible() == false ||
        await WindowManagerPlus.current.isMinimized()) {
      await WindowManagerPlus.current.show();
    } else {
      await WindowManagerPlus.current.hide();
    }
  },
);
MenuItemBase exitMenu = MenuItemLabel(label: 'Exit', onClicked: (_) => exit(1));
