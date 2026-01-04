import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';

// Base screen for legal/info documents
class _DocumentScreen extends StatelessWidget {
  final String title;
  final Widget content;

  const _DocumentScreen({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}

// Terms of Service
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocumentScreen(
      title: 'Terms of Service',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Updated: January 4, 2026',
            style: TextStyle(
              color: AppColors.white50,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            '1. Acceptance of Terms',
            'By downloading, installing, or using Skeletal-PT ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
          ),
          
          _buildSection(
            '2. Description of Service',
            'Skeletal-PT is a fitness tracking application that uses your device camera and AI-powered pose detection to:\n\n'
            '• Track your workout exercises and repetitions\n'
            '• Analyze your form and technique in real-time\n'
            '• Provide voice and visual coaching feedback\n'
            '• Store your workout history and progress\n\n'
            'The App is designed for personal fitness tracking and should not replace professional medical advice or personal training.',
          ),
          
          _buildSection(
            '3. User Responsibilities',
            '3.1 Age Requirements\n'
            'You must be at least 13 years old to use the App. Users under 18 must have parental consent.\n\n'
            '3.2 Health and Safety\n'
            'You acknowledge that:\n'
            '• Physical exercise involves inherent risks\n'
            '• You should consult a healthcare professional before starting any fitness program\n'
            '• You are responsible for ensuring your physical ability to perform exercises\n'
            '• The App provides guidance but cannot guarantee injury prevention\n\n'
            '3.3 Accurate Information\n'
            'You agree to provide accurate information and maintain the security of your account credentials.',
          ),
          
          _buildSection(
            '4. Camera and Data Usage',
            '4.1 Camera Access\n'
            'The App requires camera access to track your movements during workouts. Video data is:\n'
            '• Processed locally on your device\n'
            '• NOT recorded or stored\n'
            '• NOT transmitted to our servers\n'
            '• Only used for real-time pose detection\n\n'
            '4.2 Workout Data\n'
            'Workout statistics (reps, sets, form scores, timestamps) are stored:\n'
            '• Locally on your device\n'
            '• Optionally synced to cloud storage if you create an account\n'
            '• Never sold or shared with third parties',
          ),
          
          _buildSection(
            '5. Intellectual Property',
            'All content, features, and functionality of the App, including but not limited to:\n'
            '• Software code and algorithms\n'
            '• User interface design\n'
            '• Exercise rules and form guidance\n'
            '• Voice coaching scripts\n'
            '• Graphics, logos, and branding\n\n'
            'Are the exclusive property of Skeletal-PT and are protected by copyright, trademark, and other intellectual property laws.',
          ),
          
          _buildSection(
            '6. Prohibited Uses',
            'You agree NOT to:\n\n'
            '• Reverse engineer, decompile, or disassemble the App\n'
            '• Remove or modify any proprietary notices\n'
            '• Use the App for any illegal purposes\n'
            '• Attempt to gain unauthorized access to our systems\n'
            '• Interfere with or disrupt the App\'s functionality\n'
            '• Upload malicious code or viruses\n'
            '• Impersonate another user or person',
          ),
          
          _buildSection(
            '7. Disclaimer of Warranties',
            'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:\n\n'
            '• MERCHANTABILITY\n'
            '• FITNESS FOR A PARTICULAR PURPOSE\n'
            '• ACCURACY OR RELIABILITY\n'
            '• UNINTERRUPTED OR ERROR-FREE OPERATION\n\n'
            'We do not guarantee that the App will be free from bugs, errors, or interruptions.',
          ),
          
          _buildSection(
            '8. Limitation of Liability',
            'TO THE MAXIMUM EXTENT PERMITTED BY LAW:\n\n'
            'Skeletal-PT, its affiliates, officers, employees, and partners SHALL NOT BE LIABLE for:\n\n'
            '• Any injuries, accidents, or health issues resulting from App usage\n'
            '• Incorrect form analysis or exercise guidance\n'
            '• Loss of data or workout history\n'
            '• Device damage or malfunction\n'
            '• Indirect, incidental, special, or consequential damages\n\n'
            'Your sole remedy for dissatisfaction is to stop using the App.',
          ),
          
          _buildSection(
            '9. Indemnification',
            'You agree to indemnify and hold harmless Skeletal-PT from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:\n\n'
            '• Your use of the App\n'
            '• Your violation of these Terms\n'
            '• Your violation of any rights of another person or entity',
          ),
          
          _buildSection(
            '10. Account Termination',
            'We reserve the right to:\n\n'
            '• Suspend or terminate your account at any time\n'
            '• Refuse service to anyone for any reason\n'
            '• Remove or disable access to content\n\n'
            'You may delete your account at any time through the Settings menu.',
          ),
          
          _buildSection(
            '11. Modifications to Terms',
            'We may update these Terms at any time. Changes will be effective immediately upon posting. Your continued use of the App after changes constitutes acceptance of the new Terms. We will notify users of material changes via in-app notification.',
          ),
          
          _buildSection(
            '12. Governing Law',
            'These Terms are governed by and construed in accordance with the laws of [Your Jurisdiction], without regard to its conflict of law principles. Any disputes shall be resolved in the courts of [Your Jurisdiction].',
          ),
          
          _buildSection(
            '13. Severability',
            'If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.',
          ),
          
          _buildSection(
            '14. Entire Agreement',
            'These Terms, together with our Privacy Policy, constitute the entire agreement between you and Skeletal-PT regarding the use of the App.',
          ),
          
          _buildSection(
            '15. Contact Us',
            'If you have any questions about these Terms, please contact us at:\n\n'
            'Email: legal@skeletal-pt.com\n'
            'Website: www.skeletal-pt.com',
          ),
          
          const SizedBox(height: 40),
          
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cyberLime.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BY USING SKELETAL-PT, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY THESE TERMS OF SERVICE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.cyberLime,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.cyberLime,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Privacy Policy
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocumentScreen(
      title: 'Privacy Policy',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Updated: January 4, 2026',
            style: TextStyle(
              color: AppColors.white50,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            'Introduction',
            'Skeletal-PT ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
          ),
          
          _buildSection(
            '1. Information We Collect',
            '1.1 Information You Provide\n'
            '• Account information (name, email, password)\n'
            '• Profile details (age, weight, fitness goals)\n'
            '• Fitness preferences (equipment, experience level)\n\n'
            '1.2 Automatically Collected Information\n'
            '• Device information (model, OS version, unique identifiers)\n'
            '• Usage data (app interactions, session duration)\n'
            '• Crash reports and performance data\n\n'
            '1.3 Workout Data\n'
            '• Exercise names and types\n'
            '• Repetitions, sets, and workout duration\n'
            '• Form scores and quality metrics\n'
            '• Timestamps and workout history\n\n'
            '1.4 Camera Data\n'
            '• Real-time pose detection landmarks\n'
            '• Body joint angles and positions\n'
            '• Movement tracking data\n\n'
            'IMPORTANT: Video from your camera is:\n'
            '✓ Processed locally on your device\n'
            '✓ NEVER recorded or saved\n'
            '✓ NEVER transmitted to our servers\n'
            '✓ NEVER shared with third parties',
          ),
          
          _buildSection(
            '2. How We Use Your Information',
            'We use your information to:\n\n'
            '• Provide and maintain the App\'s functionality\n'
            '• Track your workout progress and statistics\n'
            '• Analyze your form and provide coaching feedback\n'
            '• Send workout reminders and notifications (if enabled)\n'
            '• Improve app performance and user experience\n'
            '• Diagnose technical problems\n'
            '• Comply with legal obligations',
          ),
          
          _buildSection(
            '3. Data Storage',
            '3.1 Local Storage\n'
            'By default, all workout data is stored locally on your device using:\n'
            '• SQLite database (encrypted)\n'
            '• Secure local storage\n\n'
            '3.2 Cloud Storage (Optional)\n'
            'If you create an account, we may sync your data to secure cloud storage:\n'
            '• Data is encrypted in transit (TLS/SSL)\n'
            '• Data is encrypted at rest (AES-256)\n'
            '• Stored on secure servers in [Server Location]\n'
            '• Backed up regularly for redundancy',
          ),
          
          _buildSection(
            '4. Data Sharing and Disclosure',
            'We DO NOT sell, trade, or rent your personal information to third parties.\n\n'
            'We may share information only in these circumstances:\n\n'
            '4.1 With Your Consent\n'
            '• When you explicitly authorize sharing\n\n'
            '4.2 Service Providers\n'
            '• Cloud hosting providers\n'
            '• Analytics services (anonymized data only)\n'
            '• Customer support tools\n\n'
            '4.3 Legal Requirements\n'
            '• To comply with legal obligations\n'
            '• To protect our rights and safety\n'
            '• To prevent fraud or abuse\n\n'
            '4.4 Business Transfers\n'
            '• In the event of merger, acquisition, or asset sale',
          ),
          
          _buildSection(
            '5. Third-Party Services',
            'The App may use third-party services:\n\n'
            '• Google ML Kit (on-device pose detection)\n'
            '• Firebase (optional, for authentication and storage)\n'
            '• Analytics services (anonymized data)\n\n'
            'These services have their own privacy policies. We recommend reviewing them.',
          ),
          
          _buildSection(
            '6. Data Security',
            'We implement security measures to protect your data:\n\n'
            '• Encryption in transit and at rest\n'
            '• Secure authentication mechanisms\n'
            '• Regular security audits\n'
            '• Limited employee access\n'
            '• Secure data centers\n\n'
            'However, no method of transmission or storage is 100% secure. We cannot guarantee absolute security.',
          ),
          
          _buildSection(
            '7. Your Privacy Rights',
            'You have the right to:\n\n'
            '• Access your personal data\n'
            '• Correct inaccurate data\n'
            '• Delete your data ("right to be forgotten")\n'
            '• Export your data (data portability)\n'
            '• Opt-out of notifications\n'
            '• Revoke camera permissions\n\n'
            'To exercise these rights, contact us or use the in-app settings.',
          ),
          
          _buildSection(
            '8. Data Retention',
            '• Account data: Retained until account deletion\n'
            '• Workout history: Retained indefinitely unless deleted\n'
            '• Crash reports: Retained for 90 days\n'
            '• Analytics data: Anonymized and retained for 2 years\n\n'
            'When you delete your account, all associated data is permanently deleted within 30 days.',
          ),
          
          _buildSection(
            '9. Children\'s Privacy',
            'The App is not intended for children under 13. We do not knowingly collect data from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
          ),
          
          _buildSection(
            '10. International Data Transfers',
            'Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy.',
          ),
          
          _buildSection(
            '11. California Privacy Rights (CCPA)',
            'California residents have additional rights:\n\n'
            '• Right to know what personal information is collected\n'
            '• Right to know if personal information is sold or disclosed\n'
            '• Right to opt-out of sale of personal information\n'
            '• Right to deletion\n'
            '• Right to non-discrimination\n\n'
            'Note: We do not sell personal information.',
          ),
          
          _buildSection(
            '12. European Privacy Rights (GDPR)',
            'EU residents have rights under GDPR:\n\n'
            '• Right of access\n'
            '• Right to rectification\n'
            '• Right to erasure\n'
            '• Right to restrict processing\n'
            '• Right to data portability\n'
            '• Right to object\n'
            '• Rights related to automated decision-making',
          ),
          
          _buildSection(
            '13. Changes to This Privacy Policy',
            'We may update this Privacy Policy periodically. We will notify you of significant changes via:\n\n'
            '• In-app notification\n'
            '• Email (if you have an account)\n'
            '• Updated "Last Updated" date\n\n'
            'Continued use after changes constitutes acceptance.',
          ),
          
          _buildSection(
            '14. Contact Us',
            'For privacy-related questions or concerns:\n\n'
            'Email: privacy@skeletal-pt.com\n'
            'Address: [Your Business Address]\n'
            'Data Protection Officer: dpo@skeletal-pt.com',
          ),
          
          const SizedBox(height: 40),
          
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.electricCyan.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'YOUR PRIVACY IS IMPORTANT TO US. WE ARE COMMITTED TO PROTECTING YOUR DATA AND BEING TRANSPARENT ABOUT OUR PRACTICES.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.electricCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.electricCyan,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// About Screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocumentScreen(
      title: 'About',
      content: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyberLime, width: 4),
              color: AppColors.cyberLime.withOpacity(0.1),
            ),
            child: const Center(
              child: Text(
                '💪',
                style: TextStyle(fontSize: 60),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'SKELETAL-PT',
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
          const SizedBox(height: 8),
          const Text(
            'Version 1.0.0 (Build 1)',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.white60,
            ),
          ),
          const SizedBox(height: 32),
          
          const Text(
            'Your AI Personal Trainer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Skeletal-PT uses advanced AI and computer vision to track your workouts, analyze your form in real-time, and provide professional coaching feedback - all from your phone\'s camera.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white70,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildFeature('🎯', 'Real-Time Form Analysis', 'AI-powered pose detection'),
          _buildFeature('📊', 'Progress Tracking', 'Comprehensive workout analytics'),
          _buildFeature('🗣️', 'Voice Coaching', 'Live feedback during exercises'),
          _buildFeature('🔥', 'Gamification', 'Streaks, combos, and achievements'),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white20),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.white5,
            ),
            child: Column(
              children: [
                const Text(
                  '© 2026 Skeletal-PT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All Rights Reserved',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white60,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.white20, height: 1),
                const SizedBox(height: 16),
                const Text(
                  'Made with ❤️ for fitness enthusiasts worldwide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _workoutReminders = true;
  bool _streakAlerts = true;
  bool _achievementNotifications = true;
  bool _motivationalMessages = false;

  @override
  Widget build(BuildContext context) {
    return _DocumentScreen(
      title: 'Notifications',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggle(
            'Workout Reminders',
            'Get notified when it\'s time to train',
            _workoutReminders,
            (value) => setState(() => _workoutReminders = value),
          ),
          _buildToggle(
            'Streak Alerts',
            'Don\'t break your streak!',
            _streakAlerts,
            (value) => setState(() => _streakAlerts = value),
          ),
          _buildToggle(
            'Achievement Notifications',
            'Celebrate your milestones',
            _achievementNotifications,
            (value) => setState(() => _achievementNotifications = value),
          ),
          _buildToggle(
            'Motivational Messages',
            'Daily fitness inspiration',
            _motivationalMessages,
            (value) => setState(() => _motivationalMessages = value),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white20),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.white5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.white50,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
            activeColor: AppColors.cyberLime,
            activeTrackColor: AppColors.cyberLime.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// Voice Coach Settings Screen
class VoiceCoachSettingsScreen extends StatefulWidget {
  const VoiceCoachSettingsScreen({super.key});

  @override
  State<VoiceCoachSettingsScreen> createState() => _VoiceCoachSettingsScreenState();
}

class _VoiceCoachSettingsScreenState extends State<VoiceCoachSettingsScreen> {
  bool _enableVoice = true;
  String _selectedVoice = 'hype';
  double _volume = 0.8;

  @override
  Widget build(BuildContext context) {
    return _DocumentScreen(
      title: 'Voice Coach',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white20),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.white5,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Enable Voice Coach',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Switch(
                  value: _enableVoice,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _enableVoice = value);
                  },
                  activeColor: AppColors.cyberLime,
                  activeTrackColor: AppColors.cyberLime.withOpacity(0.3),
                ),
              ],
            ),
          ),
          
          if (_enableVoice) ...[
            const SizedBox(height: 24),
            const Text(
              'COACH PERSONALITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.white50,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildVoiceOption('hype', '🔥 Hype Man', 'YESSS! You\'re a BEAST!'),
            _buildVoiceOption('sergeant', '🎖️ Drill Sergeant', 'PUSH! Don\'t quit on me!'),
            _buildVoiceOption('zen', '🧘 Zen Master', 'Breathe. Focus. Perfect.'),
            _buildVoiceOption('science', '🔬 Science Coach', 'Good form. 87% depth.'),
            
            const SizedBox(height: 24),
            const Text(
              'VOLUME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.white50,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.white20),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.white5,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: AppColors.white60),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          onChanged: (value) {
                            setState(() => _volume = value);
                          },
                          activeColor: AppColors.cyberLime,
                          inactiveColor: AppColors.white20,
                        ),
                      ),
                      const Icon(Icons.volume_up, color: AppColors.white60),
                    ],
                  ),
                  Text(
                    '${(_volume * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceOption(String id, String title, String example) {
    final isSelected = _selectedVoice == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedVoice = id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.cyberLime : AppColors.white20,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.cyberLime.withOpacity(0.1) : AppColors.white5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.cyberLime : Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.cyberLime, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '"$example"',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.white50,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

