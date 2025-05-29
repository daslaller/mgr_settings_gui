import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';

StreamBuilder<User?> constructLoginLogic(Widget mainScreen) {
  return StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: ProgressRing());
      }
      if (snapshot.hasData) {
        return mainScreen;
      } else {
        return LoginScreen(onSuccess: (user) {});
      }
    },
  );
}

class LoginScreen extends StatefulWidget {
  final void Function(User user) onSuccess;
  final String title;

  const LoginScreen({
    super.key,
    required this.onSuccess,
    this.title = '',
  });


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


class RegisterScreen extends StatefulWidget {
  final void Function(User user) onSuccess;

  const RegisterScreen({super.key, required this.onSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? errorText;
  bool loading = false;

  Future<void> registerUser() async {
    final auth = FirebaseAuth.instance;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => errorText = 'Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => errorText = 'Passwords do not match.');
      return;
    }

    setState(() {
      errorText = null;
      loading = true;
    });

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      widget.onSuccess(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = 'Registration failed: ${e.message}');
    } finally {
      setState(() => loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
      Color(0xFF9333EA), // purple-600
      Color(0xFF2563EB), // blue-600
      Color(0xFFEC4899), // pink-600
    ],)), child: NavigationView(
      appBar: NavigationAppBar(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context, '/login'),
        ),
        title: const Text('Register'),
      ),
      content: ScaffoldPage(
        header: const PageHeader(title: Text('Create New Account')),
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
                const SizedBox(height: 12),
                InfoLabel(
                  label: 'Confirm Password',
                  child: TextBox(
                    controller: confirmPasswordController,
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
                    : FilledButton(
                  onPressed: registerUser,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
        NavigationView(
        appBar: NavigationAppBar(
        leading: IconButton(
        icon: const Icon(FluentIcons.back),
    onPressed: () => Navigator.pop(context, '/login'),
    ),
    title: const Text('Register'),
    ),
    content: ScaffoldPage(
    header: const PageHeader(title: Text('Create New Account')),
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
    const SizedBox(height: 12),
    InfoLabel(
    label: 'Confirm Password',
    child: TextBox(
    controller: confirmPasswordController,
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
        : FilledButton(
    onPressed: registerUser,
    child: const Text('Register'),
    ),
    ],
    ),
    ),
    ),
    )
    ,
    );
  }
}