import 'package:flutter/material.dart';

class WalletSettingsScreen extends StatelessWidget {
  const WalletSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet Settings', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            _buildSectionTitle('Account Management', isSmallScreen),
            SizedBox(height: isSmallScreen ? 10 : 12),
            
            _buildSettingCard(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              subtitle: 'Manage cards and payment options',
              onTap: () => _showComingSoonDialog(context, 'Payment Methods'),
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            
            _buildSettingCard(
              icon: Icons.account_balance_wallet,
              title: 'Wallet Limits',
              subtitle: 'View and manage transaction limits',
              onTap: () => _showWalletLimits(context, isSmallScreen),
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            
            _buildSettingCard(
              icon: Icons.history,
              title: 'Transaction History',
              subtitle: 'View all past transactions',
              onTap: () => Navigator.pushNamed(context, '/transactions'),
              isSmallScreen: isSmallScreen,
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Security section
            _buildSectionTitle('Security', isSmallScreen),
            SizedBox(height: isSmallScreen ? 10 : 12),
            
            _buildSettingCard(
              icon: Icons.security,
              title: 'Security Settings',
              subtitle: 'PIN, biometrics, and more',
              onTap: () => _showComingSoonDialog(context, 'Security Settings'),
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            
            _buildSettingCard(
              icon: Icons.visibility_off,
              title: 'Balance Visibility',
              subtitle: 'Control when balance is hidden',
              onTap: () => _showComingSoonDialog(context, 'Balance Visibility Settings'),
              isSmallScreen: isSmallScreen,
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Notifications section
            _buildSectionTitle('Notifications', isSmallScreen),
            SizedBox(height: isSmallScreen ? 10 : 12),
            
            _buildSettingCard(
              icon: Icons.notifications,
              title: 'Transaction Alerts',
              subtitle: 'Get notified about wallet activity',
              onTap: () => _showComingSoonDialog(context, 'Transaction Alerts'),
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            
            _buildSettingCard(
              icon: Icons.warning_amber,
              title: 'Spending Alerts',
              subtitle: 'Alert when spending exceeds limit',
              onTap: () => _showComingSoonDialog(context, 'Spending Alerts'),
              isSmallScreen: isSmallScreen,
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),
            
            // Help section
            _buildSectionTitle('Help & Support', isSmallScreen),
            SizedBox(height: isSmallScreen ? 10 : 12),
            
            _buildSettingCard(
              icon: Icons.help_outline,
              title: 'FAQs',
              subtitle: 'Common questions about wallet',
              onTap: () => _showComingSoonDialog(context, 'FAQs'),
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 8 : 10),
            
            _buildSettingCard(
              icon: Icons.support_agent,
              title: 'Contact Support',
              subtitle: 'Get help with wallet issues',
              onTap: () => Navigator.pushNamed(context, '/chatbot'),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isSmallScreen ? 17 : 19,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
  
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: isSmallScreen ? 22 : 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
  
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 12),
            Text('Coming Soon'),
          ],
        ),
        content: Text('$feature will be available in a future update.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
  void _showWalletLimits(BuildContext context, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Wallet Limits'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLimitItem('Daily Withdrawal', 'KES 50,000', isSmallScreen),
              const Divider(),
              _buildLimitItem('Daily Spending', 'KES 100,000', isSmallScreen),
              const Divider(),
              _buildLimitItem('Monthly Total', 'KES 1,000,000', isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'To increase your limits, complete KYC verification and contact support.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLimitItem(String label, String amount, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

