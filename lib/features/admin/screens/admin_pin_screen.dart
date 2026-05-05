import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crypto_util.dart';

class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _isSetup = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = prefs.getString(AppConstants.kAdminPinHash);
    setState(() => _isSetup = pinHash == null);
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length < AppConstants.minPinLength) {
      _showError('PIN must be at least ${AppConstants.minPinLength} digits');
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();

    if (_isSetup) {
      final confirm = _confirmController.text.trim();
      if (pin != confirm) {
        setState(() => _loading = false);
        _showError('PINs do not match');
        return;
      }
      await prefs.setString(AppConstants.kAdminPinHash, CryptoUtil.sha256Hash(pin));
      if (mounted) context.go('/admin/home');
    } else {
      final stored = prefs.getString(AppConstants.kAdminPinHash)!;
      if (CryptoUtil.verifyHash(pin, stored)) {
        if (mounted) context.go('/admin/home');
      } else {
        setState(() => _loading = false);
        _showError('Incorrect PIN');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSetup ? 'Set Admin PIN' : 'Admin Login'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 64, color: cs.primary),
                  const SizedBox(height: 24),
                  Text(
                    _isSetup ? 'Create a PIN to protect admin access' : 'Enter your admin PIN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pinController,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    maxLength: AppConstants.maxPinLength,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: const Icon(Icons.pin_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: _isSetup ? null : (_) => _submit(),
                  ),
                  if (_isSetup) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscure,
                      keyboardType: TextInputType.number,
                      maxLength: AppConstants.maxPinLength,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                        prefixIcon: Icon(Icons.pin_rounded),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isSetup ? 'Set PIN' : 'Enter'),
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
