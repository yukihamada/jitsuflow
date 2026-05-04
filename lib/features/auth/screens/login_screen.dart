import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _anim;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<FeatureAuthBloc>().add(
            AuthMagicLinkRequested(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: BlocConsumer<FeatureAuthBloc, FeatureAuthState>(
        listener: (ctx, state) {
          if (state is FeatureAuthAuthenticated) ctx.go('/');
        },
        builder: (ctx, state) {
          return Stack(
            children: [
              // Background glow
              Positioned(
                top: -120,
                left: -80,
                child: _GlowBlob(color: const Color(0xFFB91C1C), size: 420),
              ),
              Positioned(
                bottom: -60,
                right: -100,
                child: _GlowBlob(color: const Color(0xFFF97316), size: 320),
              ),

              // Content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      28, 0, 28,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Close button (go back as guest)
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => context.go('/'),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Logo mark
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'JF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Headline
                        const Text(
                          'Welcome back.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'メールアドレスでサインイン',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 16,
                            letterSpacing: 0.1,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Sent confirmation
                        if (state is FeatureAuthMagicLinkSent)
                          _SuccessBanner(),

                        // Error
                        if (state is FeatureAuthError)
                          _ErrorBanner(state.message),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'your@email.com',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.06),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFDC2626),
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEF4444),
                                      width: 1.5,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(color: Color(0xFFEF4444)),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'メールアドレスを入力してください';
                                  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                                    return '有効なメールアドレスを入力してください';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // CTA button
                              SizedBox(
                                height: 56,
                                child: state is FeatureAuthLoading
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _submit,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFDC2626),
                                                Color(0xFFF97316),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFDC2626)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 24,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'メールを送信',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Guest
                        Center(
                          child: GestureDetector(
                            onTap: state is FeatureAuthLoading ? null : () => context.go('/'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'ゲストとして続ける →',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.18), Colors.transparent],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF052E16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF166534), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: Color(0xFF4ADE80), size: 18),
              SizedBox(width: 8),
              Text(
                'メールを送信しました',
                style: TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'メール内のリンクをタップしてサインインしてください。',
            style: TextStyle(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('mailto:'), mode: LaunchMode.externalApplication),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF166534),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, color: Color(0xFF4ADE80), size: 15),
                  SizedBox(width: 6),
                  Text(
                    'メールアプリを開く',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF450A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF991B1B), width: 1),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 14),
      ),
    );
  }
}
