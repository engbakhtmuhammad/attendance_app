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
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final sp = context.read<StudentProvider>();
    final client = ApiClient(serverIp: sp.serverIp!);

    try {
      Map<String, dynamic> res;
      if (_isRegistering) {
        res = await client.register(
          userId: _idController.text.trim(),
          name: _nameController.text.trim(),
          password: _passwordController.text.trim(),
          deviceId: sp.deviceId!,
        );
        if (!mounted) return;
        if (res['statusCode'] == 201) {
          await sp.setLoggedIn(
            userId: _idController.text.trim(),
            name: _nameController.text.trim(),
            sessionToken: '',
          );
          if (!mounted) return;
          context.go('/student/pending');
        } else {
          _showError(res['error'] ?? 'Registration failed');
        }
      } else {
        res = await client.login(
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
          );
          if (!mounted) return;
          context.go('/student/class');
        } else if (res['status'] == 'pending') {
          await sp.setLoggedIn(
            userId: _idController.text.trim(),
            name: _nameController.text.trim().isEmpty
                ? _idController.text.trim()
                : _nameController.text.trim(),
            sessionToken: '',
          );
          if (!mounted) return;
          context.go('/student/pending');
        } else {
          _showError(res['error'] ?? 'Login failed');
        }
      }
    } catch (e) {
      _showError('Connection error: $e');
    }

    setState(() => _loading = false);
  }

  void _showError(String msg) {
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
      appBar: AppBar(
        title: Text(_isRegistering ? 'Register' : 'Student Login'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _isRegistering
                          ? Icons.person_add_rounded
                          : Icons.person_rounded,
                      size: 64,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        hintText: 'e.g. 2022-BSCS-001',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      textInputAction: _isRegistering
                          ? TextInputAction.next
                          : TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    if (_isRegistering) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            _isRegistering && (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isRegistering ? 'Register' : 'Login'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() => _isRegistering = !_isRegistering),
                      child: Text(
                        _isRegistering
                            ? 'Already have an account? Login'
                            : 'New student? Register',
                      ),
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
