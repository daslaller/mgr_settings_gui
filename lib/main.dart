import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mgr_settings_gui/screens/config_screen.dart';
import 'package:mgr_settings_gui/screens/login/login_screen.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'firebase_options.dart';

Size configScreenSize = Size(1280, 768);
String title = 'MGR Mobilx PBX';
String splashImagePath = 'assets/mobilx_logo.png';
String appIconPath = 'assets/mobilx_icon.ico';
String trayIconPath = 'assets/mobilx_icon.ico';
Menu contextMenu = Menu();

SystemTray systemTray = SystemTray();

const WindowOptions applicationWindowOptions = WindowOptions(
  titleBarStyle: TitleBarStyle.hidden,
  windowButtonVisibility: false,
  size: Size(1280, 768),
  center: true,
  alwaysOnTop: false,
  fullScreen: false,
  backgroundColor: Colors.transparent,
  skipTaskbar: true,
  title: 'MGR Mobilx PBX?',
);

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Firebase initialized.');

  await WindowManagerPlus.ensureInitialized(
    int.tryParse(args.firstOrNull ?? '0') ?? 0,
  );
  log('WindowManagerPlus initialized with ID: \$windowId');

  await systemTray.initSystemTray(
    title: "MGR Mobilx PBX",
    iconPath: trayIconPath,
  );
  log('System tray initialized.');

  systemTray.registerSystemTrayEventHandler((eventName) {
    log('System tray event: \$eventName');
    if (eventName.contains(kSystemTrayEventRightClick)) {
      systemTray.popUpContextMenu();
    }
  });
  contextMenu.buildFrom([settingsMenu, exitMenu]);
  systemTray.setContextMenu(contextMenu);
  log('System tray context menu set.');

  FlutterError.onError = (FlutterErrorDetails details) {
    log(
      'FlutterError.onError caught an error: \${details.exception}',
      stackTrace: details.stack,
      error: details.exception,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    log(
      'PlatformDispatcher.instance.onError caught an error: \$error',
      stackTrace: stackTrace,
      error: error,
    );
    return true;
  };
  log('Global error handlers set up.');

  runApp(AppInitializer(splashImage: Image.asset('assets/mobilx_logo.png')));
  log('AppInitializer started.');
}

class AppInitializer extends StatefulWidget {
  final String title;
  final Image splashImage;
  final IconData? appIcon;
  const AppInitializer({
    super.key,
    this.title = 'default title dummy',
    required this.splashImage,
    this.appIcon,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    log(
      'Displaying splash screen. IMPORTANT: Replace assets/splash_image.png with your actual image and update pubspec.yaml.',
    );
    await Future.delayed(const Duration(seconds: 3));
    await _showMainWindow();
    if (mounted) {
      setState(() {
        _showSplash = false;
        log('Splash screen finished. Displaying main application.');
      });
    }
  }

  Future<void> _showMainWindow() async {
    log('Preparing to show main window...');
    await WindowManagerPlus.current.waitUntilReadyToShow(
      applicationWindowOptions,
      () async {
        if (applicationWindowOptions.size != configScreenSize) {
          await WindowManagerPlus.current.setSize(configScreenSize);
        }
        await WindowManagerPlus.current.setAsFrameless();
        await WindowManagerPlus.current.setTitle('MGR Mobilx PBX');
        await WindowManagerPlus.current.setPreventClose(true);
        await WindowManagerPlus.current.show();
        log('Main window configured and shown.');
      },
    );
    log('mainapp received window id: \${WindowManagerPlus.current.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return FluentApp(
        home: Center(child: Image.asset('assets/splash_image.png')),
        debugShowCheckedModeBanner: false,
      );
    }
    return mgrPbxApp();
  }
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
