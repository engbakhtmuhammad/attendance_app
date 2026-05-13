import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../services/api_client.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<StudentProvider>();
      if (_idController.text.isEmpty && (sp.lastUserId?.isNotEmpty ?? false)) {
        _idController.text = sp.lastUserId!;
      }
      if (_passwordController.text.isEmpty &&
          (sp.lastPassword?.isNotEmpty ?? false)) {
        _passwordController.text = sp.lastPassword!;
      }
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final sp = context.read<StudentProvider>();
    final client = ApiClient(serverIp: sp.serverIp!);

    try {
      final res = await client.login(
        userId: _idController.text.trim(),
        password: _passwordController.text.trim(),
        deviceId: sp.deviceId!,
      );
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        await sp.setLoggedIn(
          userId: res['userId'] as String,
          name: res['name'] as String,
          sessionToken: '',
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        context.go('/student/class');
      } else {
        _showError(res['error'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Connection error: $e');
    }

    setState(() => _loading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primaryContainer,
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: 34,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use credentials created by admin to continue.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.outline),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: 'Student ID',
                            hintText: 'e.g. 2022-BSCS-001',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _loading ? null : _login,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 52)),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Login',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
