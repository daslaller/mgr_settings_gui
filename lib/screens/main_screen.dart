import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mgr_settings_gui/screens/config_screen.dart';

class MainScreen extends StatelessWidget {
  final User user;
  const MainScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
        content: Center(child: configScreenWidgetExample()),
      ),
    );
  }
}