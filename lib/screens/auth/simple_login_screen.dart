import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/common/loading_widget.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthSuccess) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        builder: (context, state) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      const Icon(
                        Icons.sports_martial_arts,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'JitsuFlow',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ブラジリアン柔術トレーニング',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Login Form Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'ログイン',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'メールアドレス',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'メールアドレスを入力してください';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return '有効なメールアドレスを入力してください';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'パスワード',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'パスワードを入力してください';
                                    }
                                    if (value.length < 6) {
                                      return 'パスワードは6文字以上にしてください';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: state is AuthLoading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              context.read<AuthBloc>().add(
                                                    AuthLoginRequested(
                                                      email: _emailController
                                                          .text
                                                          .trim(),
                                                      password:
                                                          _passwordController
                                                              .text,
                                                    ),
                                                  );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: state is AuthLoading
                                        ? const LoadingWidget()
                                        : const Text(
                                            'ログイン',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  Navigator.pushNamed(context, '/register');
                                },
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text(
                            '新規登録',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Guest Mode Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  context
                                      .read<AuthBloc>()
                                      .add(const AuthGuestLoginRequested());
                                },
                          icon: const Icon(Icons.explore, size: 20),
                          label: const Text(
                            'ゲストとして利用',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
