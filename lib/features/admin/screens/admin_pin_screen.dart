import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crypto_util.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../models/admin_model.dart';

class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen> {
  final _adminRepo = AdminRepository();
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id =
        _idController.text.trim().isEmpty ? 'admin' : _idController.text.trim();
    final pin = _pinController.text.trim();

    if (pin.length < AppConstants.minPinLength) {
      _showError('PIN must be at least ${AppConstants.minPinLength} digits');
      return;
    }

    setState(() => _loading = true);

    final admin = await _adminRepo.getById(id);
    if (!mounted) return;
    setState(() => _loading = false);

    if (admin == null) {
      _showError('Admin ID not found');
      return;
    }
    if (!CryptoUtil.verifyHash(pin, admin.pinHash)) {
      _showError('Incorrect PIN');
      return;
    }
    if (mounted) context.go('/admin/home');
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showCreateAdminSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateAdminSheet(
        onCreated: () {
          Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New admin account created')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Admin Login'),
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
                  GestureDetector(
                    onLongPress: _showCreateAdminSheet,
                    child: Icon(Icons.lock_rounded, size: 72, color: cs.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter your admin credentials',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _idController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Admin ID',
                      hintText: 'admin',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    maxLength: AppConstants.maxPinLength,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: const Icon(Icons.pin_rounded),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Login',
                            style: TextStyle(fontSize: 16)),
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

// ─── Hidden Create Admin Sheet ─────────────────────────────────────────────

class _CreateAdminSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateAdminSheet({required this.onCreated});

  @override
  State<_CreateAdminSheet> createState() => _CreateAdminSheetState();
}

class _CreateAdminSheetState extends State<_CreateAdminSheet> {
  final _repo = AdminRepository();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (id.isEmpty || name.isEmpty || pin.isEmpty) {
      _showError('All fields are required');
      return;
    }
    if (pin.length < AppConstants.minPinLength) {
      _showError('PIN must be at least ${AppConstants.minPinLength} digits');
      return;
    }
    if (pin != confirm) {
      _showError('PINs do not match');
      return;
    }

    setState(() => _loading = true);
    final exists = await _repo.idExists(id);
    if (!mounted) return;
    if (exists) {
      setState(() => _loading = false);
      _showError('Admin ID already taken');
      return;
    }

    await _repo.add(AdminModel(
      id: id,
      name: name,
      pinHash: CryptoUtil.sha256Hash(pin),
      createdAt: DateTime.now(),
    ));
    if (mounted) widget.onCreated();
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Text('Create Admin Account',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 24),
          TextField(
            controller: _idController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Admin ID',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            maxLength: AppConstants.maxPinLength,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'PIN',
              prefixIcon: const Icon(Icons.pin_rounded),
              counterText: '',
              suffixIcon: IconButton(
                icon:
                    Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            maxLength: AppConstants.maxPinLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              prefixIcon: Icon(Icons.pin_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loading ? null : _create,
            icon: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: const Text('Create Admin'),
          ),
        ],
      ),
    );
  }
}
