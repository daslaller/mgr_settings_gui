import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

// Function to handle the initial check of user authentication state.
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

  const LoginScreen({super.key, required this.onSuccess, this.title = ''});

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
    return Container(
      // Apply the background gradient from the design template
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA), // purple-600
            Color(0xFF2563EB), // blue-600
            Color(0xFFEC4899), // pink-600
          ],
        ),
      ),
      child: ScaffoldPage(
        // Remove the PageHeader to match the design
        // header: PageHeader(title: Text(widget.title)),
        content: Center(
          // Use a different ConstrainedBox or remove it based on desired responsiveness
          child: material.Card(
            // Use a Card widget to create the container effect
            // You can customize the Card's appearance with elevation, shape, etc.
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0), // Adjust padding as needed
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ), // Adjust max width
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align content to the start
                  children: [
                    Text(
                      'Login',
                      style:
                          FluentTheme.of(
                            context,
                          ).typography.display, // Use a large title style
                    ),
                    const SizedBox(height: 8), // Add some space below the title
                    Text(
                      'Welcome back! Please enter your details to login.',
                      style:
                          FluentTheme.of(
                            context,
                          ).typography.body, // Use a body style for subtitle
                    ),
                    const SizedBox(height: 20),
                    // Email Input Field with Icon
                    TextBox(
                      controller: emailController,
                      placeholder: 'Email',
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(FluentIcons.mail), // Use a mail icon
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Increased space between input fields
                    // Password Input Field with Icon
                    TextBox(
                      controller: passwordController,
                      obscureText: true,
                      placeholder: 'Password',
                      prefix: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(FluentIcons.lock), // Use a lock icon
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (errorText != null) // Keep error message
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          errorText!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Loading Indicator or Buttons
                    loading
                        ? const Center(
                          child: ProgressRing(),
                        ) // Center the loading indicator
                        : Column(
                          // Wrap buttons in a Column for vertical arrangement
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Login Button
                            FilledButton(
                              onPressed: loginUser,
                              child: const Text('Login'),
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Space between Login and social buttons
                            // "Or continue with" text
                            Center(
                              child: Text(
                                'Or continue with',
                                style:
                                    FluentTheme.of(
                                      context,
                                    ).typography.caption, // Use a caption style
                              ),
                            ),
                            const SizedBox(
                              height: 16,
                            ), // Space between text and social buttons
                            // Social Login Buttons (Example: Google and GitHub)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Login Button
                                Button(
                                  onPressed: () {
                                    // Implement Google login logic
                                  },
                                  child: Icon(
                                    FluentIcons.authenticator_app,
                                  ), // Use a Google icon
                                ),
                                const SizedBox(
                                  width: 16,
                                ), // Space between social buttons
                                // GitHub Login Button
                                Button(
                                  onPressed: () {
                                    // Implement GitHub login logic
                                  },
                                  child: const Icon(
                                    FluentIcons.giftbox,
                                  ), // Use a GitHub icon
                                ),
                                // Add more social login buttons as needed
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Space between social buttons and register prompt
                            // Register Prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style:
                                      FluentTheme.of(context).typography.body,
                                ),
                                const SizedBox(width: 4),
                                // Register Button (as a TextButton for a less prominent look)
                                Button(
                                  onPressed: navigateToRegisterScreen,
                                  child: const Text('Sign up'),
                                ),
                              ],
                            ),
                            // The original "Create Account" button is replaced by the text prompt and TextButton
                            /*
                        const SizedBox(height: 12),
                        Button(
                          // This button is removed in the new design
                          onPressed: navigateToRegisterScreen,
                          child: const Text('Create Account'),
                        ),
                        */
                          ],
                        ),
                  ],
                ),
              ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA), // purple-600
            Color(0xFF2563EB), // blue-600  // Corrected color
            Color(0xFFEC4899), // pink-600
          ],
        ),
      ),
      child: NavigationView(
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
      ),
    );
  }
}
