import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class MainScreen extends StatelessWidget {
  final User user;
  final WindowManagerPlus window;
  final WindowOptions windowOptions;
  final Widget mainScreen;
  const MainScreen({super.key, required this.user, required this.window, required this.windowOptions, required this.mainScreen});

  init() async {
    await window.waitUntilReadyToShow(windowOptions, () async {
      await window.setAsFrameless();
      await window.setPreventClose(true);
    });
  }
  @override
 build(BuildContext context)  {

    return NavigationView(
      content: ScaffoldPage(
        header: PageHeader(
          title: Text('Welcome, ${user.email ?? 'User'}'),
          commandBar: Row(
            children: [
              FilledButton(
                child: const Text('Sign Out'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
        content: Center(child: mainScreen),
      ),
    );
  }
}