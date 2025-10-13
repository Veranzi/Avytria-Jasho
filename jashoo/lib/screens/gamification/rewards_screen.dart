import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() => _loading = false);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    final rewards = const [
      {'name': '100MB Safaricom Data', 'cost': 500, 'type': 'airtime'},
      {'name': 'KES 50 Savings Withdrawal Discount', 'cost': 300, 'type': 'discount'},
      {'name': 'Visibility Boost (3 days)', 'cost': 800, 'type': 'goods'},
      {'name': 'USDT Bonus 1', 'cost': 1000, 'type': 'usdt'},
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Rewards Store', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PointsHeader(points: g.points, isSmallScreen: isSmallScreen),
            SizedBox(height: isSmallScreen ? 14 : 16),
            Expanded(
              child: _loading
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSmallScreen ? 1 : 2,
                        crossAxisSpacing: isSmallScreen ? 10 : 12,
                        mainAxisSpacing: isSmallScreen ? 10 : 12,
                        childAspectRatio: isSmallScreen ? 2.0 : 0.95,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Skeleton(height: 160),
                    )
                  : FadeTransition(
                      opacity: _fade,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmallScreen ? 1 : 2,
                          crossAxisSpacing: isSmallScreen ? 10 : 12,
                          mainAxisSpacing: isSmallScreen ? 10 : 12,
                          childAspectRatio: isSmallScreen ? 2.0 : 0.95,
                        ),
                        itemCount: rewards.length,
                        itemBuilder: (_, i) {
                          final r = rewards[i];
                          final canRedeem = g.points >= (r['cost'] as int);
                          return _RewardCard(
                            name: r['name'].toString(),
                            cost: r['cost'] as int,
                            icon: _iconForType(r['type'] as String),
                            canRedeem: canRedeem,
                            onRedeem: canRedeem ? () => g.redeemPoints(r['cost'] as int) : null,
                            isSmallScreen: isSmallScreen,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  final int points;
  final bool isSmallScreen;
  const _PointsHeader({required this.points, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: isSmallScreen ? 28 : 32),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 12 : 13,
                  ),
                ),
                Text(
                  '$points pts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 8 : 10,
              ),
            ),
            onPressed: () {
              _showHowItWorks(context, isSmallScreen);
            },
            child: Text(
              'How it works',
              style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
            ),
          )
        ],
      ),
    );
  }
  
  void _showHowItWorks(BuildContext context, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'How Points Work',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.savings,
                text: 'Earn points by saving money',
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              _InfoRow(
                icon: Icons.work_outline,
                text: 'Complete jobs to earn points',
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              _InfoRow(
                icon: Icons.star,
                text: 'Redeem points for rewards',
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text('Got it', style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSmallScreen;
  
  const _InfoRow({required this.icon, required this.text, required this.isSmallScreen});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: isSmallScreen ? 20 : 22),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String name;
  final int cost;
  final IconData icon;
  final bool canRedeem;
  final VoidCallback? onRedeem;
  final bool isSmallScreen;
  
  const _RewardCard({
    required this.name,
    required this.cost,
    required this.icon,
    required this.canRedeem,
    required this.onRedeem,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF10B981),
                  size: isSmallScreen ? 22 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 15,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$cost pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 15 : 16,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onRedeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem ? const Color(0xFF10B981) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 8 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Redeem',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'airtime':
      return Icons.network_cell;
    case 'discount':
      return Icons.discount;
    case 'goods':
      return Icons.star;
    case 'usdt':
      return Icons.currency_exchange;
    default:
      return Icons.card_giftcard;
  }
}
