import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  final _regUser = TextEditingController();
  final _regPass = TextEditingController();
  final _regEmail = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureReg = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginUser.dispose();
    _loginPass.dispose();
    _regUser.dispose();
    _regPass.dispose();
    _regEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPurple, kPurpleDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Veredicto',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kText)),
              const SizedBox(height: 4),
              const Text('Pronósticos con motor IA',
                  style: TextStyle(color: kMuted, fontSize: 14)),
              const SizedBox(height: 36),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: kPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: kMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Entrar'),
                    Tab(text: 'Registrarse'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (auth.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFef4444).withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFef4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(auth.error!,
                            style: const TextStyle(
                                color: Color(0xFFef4444), fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 300,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _LoginForm(
                      userCtrl: _loginUser,
                      passCtrl: _loginPass,
                      obscure: _obscureLogin,
                      onToggle: () =>
                          setState(() => _obscureLogin = !_obscureLogin),
                      loading: auth.loading,
                      onSubmit: () async {
                        final ok = await auth.login(
                            _loginUser.text.trim(), _loginPass.text);
                        if (ok && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                    ),
                    _RegisterForm(
                      userCtrl: _regUser,
                      passCtrl: _regPass,
                      emailCtrl: _regEmail,
                      obscure: _obscureReg,
                      onToggle: () =>
                          setState(() => _obscureReg = !_obscureReg),
                      loading: auth.loading,
                      onSubmit: () async {
                        final ok = await auth.register(
                          _regUser.text.trim(),
                          _regPass.text,
                          _regEmail.text.trim().isEmpty
                              ? null
                              : _regEmail.text.trim(),
                        );
                        if (ok && context.mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController userCtrl, passCtrl;
  final bool obscure, loading;
  final VoidCallback onToggle, onSubmit;

  const _LoginForm({
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggle,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: userCtrl,
          decoration: const InputDecoration(
            labelText: 'Usuario',
            prefixIcon: Icon(Icons.person_outline, color: kMuted),
          ),
          style: const TextStyle(color: kText),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passCtrl,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline, color: kMuted),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: kMuted),
              onPressed: onToggle,
            ),
          ),
          style: const TextStyle(color: kText),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Entrar'),
          ),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final TextEditingController userCtrl, passCtrl, emailCtrl;
  final bool obscure, loading;
  final VoidCallback onToggle, onSubmit;

  const _RegisterForm({
    required this.userCtrl,
    required this.passCtrl,
    required this.emailCtrl,
    required this.obscure,
    required this.onToggle,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: userCtrl,
          decoration: const InputDecoration(
            labelText: 'Usuario',
            prefixIcon: Icon(Icons.person_outline, color: kMuted),
          ),
          style: const TextStyle(color: kText),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (opcional)',
            prefixIcon: Icon(Icons.email_outlined, color: kMuted),
          ),
          style: const TextStyle(color: kText),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passCtrl,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Contraseña (mín. 6)',
            prefixIcon: const Icon(Icons.lock_outline, color: kMuted),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: kMuted),
              onPressed: onToggle,
            ),
          ),
          style: const TextStyle(color: kText),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Crear cuenta'),
          ),
        ),
      ],
    );
  }
}
