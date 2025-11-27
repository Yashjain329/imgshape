// lib/src/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, String>> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'email': 'Unknown', 'id': ''};
    return {'email': user.email ?? 'Unknown', 'id': user.id};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.heroBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Profile'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<Map<String, String>>(
            future: _loadUserData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final email = snapshot.data!['email']!;
              final userId = snapshot.data!['id']!;
              return ListView(
                padding: const EdgeInsets.all(14.0),
                children: [
                  _profileHeader(context, email),
                  const SizedBox(height: 20),
                  _infoSection(context, email, userId),
                  const SizedBox(height: 20),
                  _settingsSection(context),
                  const SizedBox(height: 20),
                  _logoutSection(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String email) => GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.accentCyan,
          child: const Icon(Icons.person, size: 48, color: AppTheme.bgBottom),
        ),
        const SizedBox(height: 12),
        Text(email.split('@')[0].capitalize(),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(email,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.mutedText)),
      ]),
    ),
  );

  Widget _infoSection(BuildContext context, String email, String id) => GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(children: [
        _infoRow(Icons.email_outlined, 'Email', email, AppTheme.accentCyan),
        const Divider(thickness: 0.2),
        _infoRow(Icons.fingerprint_outlined, 'User ID',
            '${id.substring(0, 12)}...', AppTheme.accentViolet),
      ]),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w500))
              ]),
        )
      ]);

  Widget _settingsSection(BuildContext context) => Column(
    children: [
      Text('Settings',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      _settingsTile(context, 'Change Password', Icons.lock_outlined,
              () => context.push('/reset')),
      const SizedBox(height: 10),
      _settingsTile(context, 'Privacy Settings', Icons.shield_outlined, () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')));
      }),
      const SizedBox(height: 10),
      _settingsTile(context, 'Help & Support', Icons.help_outline, () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')));
      }),
    ],
  );

  Widget _settingsTile(BuildContext context, String title, IconData icon,
      VoidCallback onTap) =>
      PressableGlassCard(
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.accentCyan),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
        ),
      );

  Widget _logoutSection(BuildContext context) => Center(
    child: ElevatedButton.icon(
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go('/');
      },
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
    ),
  );
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}