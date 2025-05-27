import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mgr_settings_gui/screens/register_screen.dart';
import 'package:mgr_settings_gui/widgets/configApp.dart';
import 'package:mgr_settings_gui/widgets/loginApp.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'firebase_options.dart';

Size configScreenSize = Size(800, 600);
Menu contextMenu = Menu();

SystemTray systemTray = SystemTray();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Starting application debug/sample/standalone application...');
  WidgetsFlutterBinding.ensureInitialized();
  log('working with args: $args');

  await WindowManagerPlus.ensureInitialized(
    int.parse(args.firstOrNull ?? '0'),
  ).then((_) async {
    switch (args) {
      case []:
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
        runApp(
          FluentApp(
            initialRoute: '/login',
            routes: {
              '/login': (context) => loginApp,
              '/config': (context) => configApp,
              '/register': (context) => RegisterScreen(onSuccess: (user) {}),
            },
          ), // Program entrypoint.
        );

        log('mainapp received window id: ${WindowManagerPlus.current.id}');
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
}

MenuItemBase settingsMenu = MenuItemLabel(
  label: 'Show',
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
