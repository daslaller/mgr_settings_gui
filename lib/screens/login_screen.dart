import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import 'register_screen.dart'; // Import the new register screen

class LoginScreen extends StatefulWidget {
  final void Function(User user) onSuccess;
  final WindowManagerPlus window;
  final WindowOptions windowOptions;
  final String title;

  const LoginScreen({
    super.key,
    required this.onSuccess,
    required this.window,
    required this.windowOptions,
    this.title = '',
  });

  init() async {
    await window.waitUntilReadyToShow(windowOptions, () async {
      await window.setAsFrameless();
      await window.setPreventClose(true);
    });
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorText;
  bool loading = false;

  Future<void> loginUser() async {
    // Renamed from loginOrCreate
    final auth = FirebaseAuth.instance;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorText = 'Please enter both email and password.');
      return;
    }

    setState(() {
      errorText = null;
      loading = true;
    });

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      widget.onSuccess(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      // Removed user-not-found block for auto-registration
      setState(() => errorText = 'Login failed: ${e.message}');
    } finally {
      setState(() => loading = false);
    }
  }

  void navigateToRegisterScreen() {
    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => RegisterScreen(onSuccess: widget.onSuccess),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: PageHeader(title: Text(widget.title)),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InfoLabel(
                  label: 'Email',
                  child: TextBox(
                    controller: emailController,
                    placeholder: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: 'Password',
                  child: TextBox(
                    controller: passwordController,
                    obscureText: true,
                    placeholder: '••••••••',
                  ),
                ),
                const SizedBox(height: 20),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      errorText!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                loading
                    ? const ProgressRing()
                    : Column(
                      // Wrap buttons in a Column
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: loginUser, // Updated to loginUser
                          child: const Text('Login'),
                        ),
                        const SizedBox(height: 12),
                        Button(
                          // Changed to a regular Button for secondary action
                          onPressed: navigateToRegisterScreen,
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
