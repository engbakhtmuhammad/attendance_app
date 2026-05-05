import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<bool> _adminPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kAdminPinHash) != null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.fact_check_rounded, size: 80, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Attendance',
                textAlign: TextAlign.center,
                style: tt.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Secure Offline System',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(color: cs.outline),
              ),
              const Spacer(),
              _RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin',
                subtitle: 'Manage classes & sessions',
                color: cs.primaryContainer,
                onColor: cs.onPrimaryContainer,
                onTap: () async {
                  final pinSet = await _adminPinSet();
                  if (context.mounted) {
                    context.push('/admin/pin',
                        extra: {'setup': !pinSet});
                  }
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.school_rounded,
                title: 'Student',
                subtitle: 'Mark your attendance',
                color: cs.secondaryContainer,
                onColor: cs.onSecondaryContainer,
                onTap: () => context.push('/student/connect'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: onColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: onColor, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: onColor.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: onColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
