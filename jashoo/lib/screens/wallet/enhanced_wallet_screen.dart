import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../widgets/voice_assistant_button.dart';

class EnhancedWalletScreen extends StatefulWidget {
  const EnhancedWalletScreen({super.key});

  @override
  State<EnhancedWalletScreen> createState() => _EnhancedWalletScreenState();
}

class _EnhancedWalletScreenState extends State<EnhancedWalletScreen> {
  bool _balancesVisible = false;
  bool _isVerifying = false;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final response = await ApiService().getPaymentMethods();
      if (response['success'] == true) {
        setState(() {
          _paymentMethods = List<Map<String, dynamic>>.from(response['data']['methods'] ?? []);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _verifyAndShowBalance() async {
    final password = await _showPasswordDialog();
    if (password == null) return;

    setState(() => _isVerifying = true);

    try {
      // In a real app, verify password with backend
      // For now, just show the balance
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _balancesVisible = true;
        _isVerifying = false;
      });

      // Auto-hide after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() => _balancesVisible = false);
        }
      });
    } catch (e) {
      setState(() => _isVerifying = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Identity'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Enter your password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPaymentMethod() async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'card'),
            ),
            ListTile(
              leading: Icon(Icons.payment, color: Colors.purple.shade700),
              title: const Text('Stripe'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
            ListTile(
              leading: Icon(Icons.account_balance, color: Colors.blue.shade700),
              title: const Text('PayPal'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pop(context, 'paypal'),
            ),
          ],
        ),
      ),
    );

    if (method != null) {
      if (method == 'stripe') {
        await _setupStripe();
      } else if (method == 'paypal') {
        await _setupPayPal();
      } else {
        await _setupCard();
      }
    }
  }

  Future<void> _setupStripe() async {
    try {
      // Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Jasho',
          customerId: 'customer_id', // Get from backend
          customerEphemeralKeySecret: 'ephemeral_key', // Get from backend
          setupIntentClientSecret: 'setup_intent_secret', // Get from backend
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe payment method added successfully')),
      );
      
      _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add Stripe: $e')),
      );
    }
  }

  Future<void> _setupPayPal() async {
    // Implement PayPal setup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PayPal integration coming soon')),
    );
  }

  Future<void> _setupCard() async {
    // Implement card setup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card setup coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          IconButton(
            icon: Icon(_balancesVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: _balancesVisible 
                ? () => setState(() => _balancesVisible = false)
                : _verifyAndShowBalance,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await wallet.loadBalance();
          _loadPaymentMethods();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              _buildBalanceCard(wallet),
              SizedBox(height: 20.h),
              
              // Quick Actions
              _buildQuickActions(),
              SizedBox(height: 24.h),
              
              // Payment Methods
              _buildPaymentMethodsSection(),
              SizedBox(height: 24.h),
              
              // Recent Transactions
              _buildRecentTransactions(wallet),
            ],
          ),
        ),
      ),
      floatingActionButton: const VoiceAssistantButton(), // Voice navigation for PWD users
    );
  }

  Widget _buildBalanceCard(WalletProvider wallet) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8.h),
          
          // Main balance
          Row(
            children: [
              Text(
                _balancesVisible 
                    ? 'KES ${wallet.kesBalance.toStringAsFixed(2)}'
                    : 'KES ****',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              if (_isVerifying)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Other balances
          Row(
            children: [
              Expanded(
                child: _buildMiniBalance(
                  'USDT',
                  _balancesVisible 
                      ? wallet.usdtBalance.toStringAsFixed(4)
                      : '****',
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildMiniBalance(
                  'USD',
                  _balancesVisible 
                      ? wallet.usdBalance.toStringAsFixed(2)
                      : '****',
                ),
              ),
            ],
          ),
          
          if (!_balancesVisible) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.white, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Tap eye icon to reveal balance',
                    style: TextStyle(
                      fontSize: 12.sp,
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

  Widget _buildMiniBalance(String currency, String amount) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currency,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            Icons.arrow_downward,
            'Deposit',
            Colors.green,
            () => Navigator.pushNamed(context, '/deposit'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            Icons.arrow_upward,
            'Withdraw',
            Colors.orange,
            () => Navigator.pushNamed(context, '/withdraw'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            Icons.send,
            'Send',
            Colors.blue,
            () => Navigator.pushNamed(context, '/transfer'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _addPaymentMethod,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        if (_paymentMethods.isEmpty)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'No payment methods added yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            _getPaymentMethodIcon(method['type']),
            size: 32.sp,
            color: const Color(0xFF10B981),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method['name'] ?? 'Payment Method',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (method['lastFour'] != null)
                  Text(
                    '**** ${method['lastFour']}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String? type) {
    switch (type) {
      case 'stripe':
        return Icons.payment;
      case 'paypal':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Widget _buildRecentTransactions(WalletProvider wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/transactionHistory'),
              child: const Text('See All'),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        if (wallet.transactions.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.h),
              child: Text(
                'No transactions yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ...wallet.transactions.take(5).map((txn) => ListTile(
            leading: CircleAvatar(
              backgroundColor: txn.type == 'deposit' 
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              child: Icon(
                txn.type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                color: txn.type == 'deposit' ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(txn.description),
            subtitle: Text(txn.date.toString()),
            trailing: Text(
              '${txn.type == 'deposit' ? '+' : '-'}${txn.amount.toStringAsFixed(2)} ${txn.currencyCode}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: txn.type == 'deposit' ? Colors.green : Colors.orange,
              ),
            ),
          )).toList(),
      ],
    );
  }
}

