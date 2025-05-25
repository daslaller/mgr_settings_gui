import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';

class LoginScreen extends StatefulWidget {
  final void Function(User user) onSuccess;

  const LoginScreen({super.key, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorText;
  bool loading = false;

  Future<void> loginOrCreate() async {
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
      if (e.code == 'user-not-found') {
        try {
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          widget.onSuccess(userCredential.user!);
        } on FirebaseAuthException {
          setState(() => errorText = 'Registration failed: \${createError.message}');
        }
      } else {
        setState(() => errorText = 'Login failed: \${e.message}');
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: const PageHeader(title: Text('Swish Login')),
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
                      style:  TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                loading
                    ? const ProgressRing()
                    : FilledButton(
                        onPressed: loginOrCreate,
                        child: const Text('Login / Register'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}