import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mgr_settings_gui/widgets/configApp.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../screens/login_screen.dart';
import '../screens/main_screen.dart';

WindowOptions mainScreenWindowOptions = WindowOptions(
  center: true,
  size: Size(800, 600),
  skipTaskbar: true,
  windowButtonVisibility: false,
  titleBarStyle: TitleBarStyle.hidden,
);
WindowOptions loginScreenWindowOptions = WindowOptions(
  center: true,
  size: Size(800, 600),
  skipTaskbar: true,
  windowButtonVisibility: false,
  titleBarStyle: TitleBarStyle.hidden,
);

FluentApp get loginApp => FluentApp(
  title: 'Mgr PBX',
  home: StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: ProgressRing());
      }
      if (snapshot.hasData) {
        return MainScreen(
          user: snapshot.data!,
          window: WindowManagerPlus.current,
          windowOptions: mainScreenWindowOptions,
          mainScreen: configApp,
        )..init();
      } else {
        return LoginScreen(
          onSuccess: (user) {},
          window: WindowManagerPlus.current,
          windowOptions: loginScreenWindowOptions,
        )..init();
      }
    },
  ),
  theme: FluentThemeData(brightness: Brightness.dark, accentColor: Colors.blue),
  debugShowCheckedModeBanner: false,
);
