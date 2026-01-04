import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import 'settings_detail_screens.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'SKELETAL',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.cyberLime,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: AppColors.cyberLime.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const Text(
              '-PT',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white60,
              ),
            ),
            const SizedBox(height: 32),

            // Profile Section
            _buildSectionHeader('PROFILE'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Name, age, fitness goals',
                  onTap: () {
                    // TODO: Navigate to edit profile
                    HapticFeedback.lightImpact();
                  },
                ),
                _SettingsItem(
                  icon: Icons.fitness_center,
                  title: 'Fitness Preferences',
                  subtitle: 'Equipment, experience level',
                  onTap: () {
                    // TODO: Navigate to fitness preferences
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('APP SETTINGS'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Workout reminders, streak alerts',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.volume_up_outlined,
                  title: 'Voice Coach',
                  subtitle: 'Voice feedback during workouts',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VoiceCoachSettingsScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.vibration,
                  title: 'Haptics',
                  subtitle: 'Vibration feedback',
                  trailing: const _HapticToggle(),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data & Storage
            _buildSectionHeader('DATA & STORAGE'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.download_outlined,
                  title: 'Export Data',
                  subtitle: 'Download your workout history',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Implement export
                  },
                ),
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showClearCacheDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account
            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Change Email',
                  subtitle: 'Update your email address',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to change email
                  },
                ),
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to change password
                  },
                ),
                _SettingsItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Log out of your account',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showSignOutDialog(context);
                  },
                  textColor: AppColors.neonCrimson,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Legal
            _buildSectionHeader('LEGAL'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.gavel_outlined,
                  title: 'Licenses',
                  subtitle: 'Open source licenses',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showLicensePage(
                      context: context,
                      applicationName: 'Skeletal-PT',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 Skeletal-PT. All rights reserved.',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About
            _buildSectionHeader('ABOUT'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'About Skeletal-PT',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to help
                  },
                ),
                _SettingsItem(
                  icon: Icons.rate_review_outlined,
                  title: 'Rate Us',
                  subtitle: 'Leave a review',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Open store rating
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionHeader('DANGER ZONE'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              items: [
                _SettingsItem(
                  icon: Icons.warning_outlined,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showDeleteAccountDialog(context);
                  },
                  textColor: AppColors.neonCrimson,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Skeletal-PT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cyberLime,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0 (Build 1)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2026 All Rights Reserved',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.white50,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<_SettingsItem> items}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white20, width: 1),
        color: AppColors.white5,
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            return Column(
              children: [
                _buildSettingsItem(context, item),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.white10,
                    indent: 56,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, _SettingsItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: item.textColor ?? AppColors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: item.textColor ?? Colors.white,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.white50,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.trailing != null)
                item.trailing!
              else if (item.onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.white30,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.white20),
        ),
        title: const Text(
          'Clear Cache?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This will free up storage space but may require re-downloading some data.',
          style: TextStyle(color: AppColors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear cache
              HapticFeedback.mediumImpact();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.cyberLime)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.white20),
        ),
        title: const Text(
          'Sign Out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement sign out
              HapticFeedback.mediumImpact();
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.neonCrimson)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neonCrimson, width: 2),
        ),
        title: const Text(
          '⚠️ Delete Account?',
          style: TextStyle(color: AppColors.neonCrimson, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This action is PERMANENT and cannot be undone. All your workout data, progress, and stats will be deleted forever.',
          style: TextStyle(color: AppColors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              HapticFeedback.heavyImpact();
            },
            child: const Text('Delete Forever', style: TextStyle(color: AppColors.neonCrimson, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.textColor,
  });
}

class _HapticToggle extends StatefulWidget {
  const _HapticToggle();

  @override
  State<_HapticToggle> createState() => _HapticToggleState();
}

class _HapticToggleState extends State<_HapticToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      onChanged: (value) {
        setState(() => _enabled = value);
        HapticFeedback.lightImpact();
        // TODO: Save preference
      },
      activeColor: AppColors.cyberLime,
      activeTrackColor: AppColors.cyberLime.withOpacity(0.3),
    );
  }
}

