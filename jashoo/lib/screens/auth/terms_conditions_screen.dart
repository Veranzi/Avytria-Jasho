import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 700 || constraints.maxWidth < 400;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  isSmallScreen,
                  'Data Privacy & GDPR Compliance',
                  'Jasho is committed to protecting your personal data in compliance with the General Data Protection Regulation (GDPR) and other applicable data protection laws.\n\n'
                  'We collect, process, and store your personal information including but not limited to:\n'
                  '• Full name and contact information\n'
                  '• Phone number and email address\n'
                  '• Location data\n'
                  '• Financial transaction data\n'
                  '• Biometric data (if you use face/voice recognition features)\n\n'
                  'Your data will be used solely for:\n'
                  '• Providing financial services\n'
                  '• Fraud detection and prevention\n'
                  '• Service improvement\n'
                  '• Legal compliance',
                ),
                _buildSection(
                  isSmallScreen,
                  'Your Rights',
                  'Under GDPR, you have the right to:\n'
                  '• Access your personal data\n'
                  '• Rectify inaccurate data\n'
                  '• Erase your data ("right to be forgotten")\n'
                  '• Restrict processing of your data\n'
                  '• Data portability\n'
                  '• Object to processing\n'
                  '• Withdraw consent at any time',
                ),
                _buildSection(
                  isSmallScreen,
                  'Data Security',
                  'We implement appropriate technical and organizational measures to ensure a level of security appropriate to the risk, including:\n'
                  '• Encryption of data in transit and at rest\n'
                  '• Regular security assessments\n'
                  '• Access controls and authentication\n'
                  '• Regular backups and disaster recovery',
                ),
                _buildSection(
                  isSmallScreen,
                  'Use of Services',
                  'By using Jasho, you agree to:\n'
                  '• Provide accurate and truthful information\n'
                  '• Use the service for legitimate purposes only\n'
                  '• Not engage in fraudulent activities\n'
                  '• Comply with all applicable laws and regulations\n'
                  '• Maintain the confidentiality of your account credentials',
                ),
                _buildSection(
                  isSmallScreen,
                  'Gig Posting & Verification',
                  'All gig postings are subject to AI-powered legitimacy verification. We reserve the right to:\n'
                  '• Reject posts that fail verification\n'
                  '• Warn users posting suspicious content\n'
                  '• Block or remove users who repeatedly post fraudulent content\n'
                  '• Report suspected criminal activity to authorities',
                ),
                _buildSection(
                  isSmallScreen,
                  'Financial Transactions',
                  'All financial transactions are subject to:\n'
                  '• Transaction limits as per regulatory requirements\n'
                  '• Anti-money laundering (AML) checks\n'
                  '• Know Your Customer (KYC) verification\n'
                  '• Fraud detection monitoring',
                ),
                _buildSection(
                  isSmallScreen,
                  'Savings & Loans',
                  'Savings goals and loan products are provided subject to:\n'
                  '• Eligibility criteria\n'
                  '• Credit assessment\n'
                  '• Terms and conditions specific to each product\n'
                  '• Applicable fees and interest rates',
                ),
                _buildSection(
                  isSmallScreen,
                  'Notifications',
                  'You consent to receive:\n'
                  '• In-app notifications\n'
                  '• SMS alerts for important account activities\n'
                  '• Fraud and security alerts\n'
                  '• Transaction confirmations\n'
                  '• Overspending warnings',
                ),
                _buildSection(
                  isSmallScreen,
                  'Accessibility Features',
                  'Our accessibility features including voice and face recognition:\n'
                  '• Are optional and can be disabled at any time\n'
                  '• Store biometric data securely on your device\n'
                  '• Comply with accessibility standards\n'
                  '• Are designed to help users with disabilities',
                ),
                _buildSection(
                  isSmallScreen,
                  'Limitation of Liability',
                  'Jasho shall not be liable for:\n'
                  '• Indirect or consequential losses\n'
                  '• Loss of profits or business opportunities\n'
                  '• Service interruptions due to force majeure\n'
                  '• Third-party service failures',
                ),
                _buildSection(
                  isSmallScreen,
                  'Changes to Terms',
                  'We reserve the right to modify these terms at any time. Users will be notified of significant changes via:\n'
                  '• In-app notification\n'
                  '• Email notification\n'
                  '• SMS notification',
                ),
                _buildSection(
                  isSmallScreen,
                  'Contact & Data Protection Officer',
                  'For questions about these terms or to exercise your data protection rights, contact us at:\n\n'
                  'Email: privacy@jasho.com\n'
                  'Phone: +254 700 000 000\n'
                  'Data Protection Officer: dpo@jasho.com',
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(bool isSmallScreen, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 18.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            content,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
