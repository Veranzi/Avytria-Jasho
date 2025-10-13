// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/savings_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/voice_assistant_icon_button.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _amountController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savings = context.watch<SavingsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Savings', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          // Voice navigation for PWD users
          VoiceAssistantIconButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Voluntary Saving'),
            Tab(text: 'Standing Order'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGoalSheet(context, savings, isSmallScreen),
        icon: const Icon(Icons.add),
        label: Text('New goal', style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Voluntary Saving Tab
          _buildSavingsTab(context, savings, false, isSmallScreen),
          // Standing Order Tab
          _buildSavingsTab(context, savings, true, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSavingsTab(BuildContext context, SavingsProvider savings, bool isStandingOrder, bool isSmallScreen) {
    final filteredGoals = savings.goals.where((g) => g.isStandingOrder == isStandingOrder).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card explaining the tier
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isStandingOrder ? Icons.repeat : Icons.volunteer_activism,
                  color: const Color(0xFF10B981),
                  size: isSmallScreen ? 24 : 28,
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStandingOrder ? 'Automatic Savings' : 'Voluntary Savings',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isStandingOrder
                            ? 'Set an amount to auto-deduct from your wallet regularly.'
                            : 'Save manually whenever you want towards your goals.',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 14 : 18),
          
          _PointsFromSavings(points: savings.pointsEarnedFromSavings, isSmallScreen: isSmallScreen),
          SizedBox(height: isSmallScreen ? 14 : 18),
          
          Text(
            'Your ${isStandingOrder ? "automatic" : "voluntary"} goals',
            style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          
          filteredGoals.isEmpty
              ? Container(
                  padding: EdgeInsets.all(isSmallScreen ? 28 : 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.savings_outlined, size: isSmallScreen ? 56 : 64, color: Colors.grey[400]),
                        SizedBox(height: isSmallScreen ? 14 : 16),
                        Text(
                          'No ${isStandingOrder ? "standing order" : "voluntary"} goals yet',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: Colors.grey[600]),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        Text(
                          'Tap the + button to create one',
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : _GoalsList(
                  goals: filteredGoals,
                  onContribute: (id) => _contributeDialog(context, id, isSmallScreen),
                  isSmallScreen: isSmallScreen,
                ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _contributeDialog(BuildContext context, String goalId, bool isSmallScreen) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Contribute to Goal', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (KES)',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(controller.text.trim()) ?? 0;
              if (amt > 0) {
                context.read<SavingsProvider>().contribute(goalId, amt);
                context.read<GamificationProvider>().earnPoints(amt.floor());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ KES ${amt.toStringAsFixed(0)} added to savings!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: Text('Save', style: TextStyle(fontSize: isSmallScreen ? 14 : 15)),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateGoalSheet(BuildContext context, SavingsProvider savings, bool isSmallScreen) async {
    String selectedTier = 'Voluntary';
    String selectedFrequency = 'Weekly';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Savings Goal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 14 : 16),
                    
                    // Goal name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Goal name',
                        hintText: 'e.g., New Phone',
                        prefixIcon: const Icon(Icons.flag),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Target amount
                    TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target amount (KES)',
                        hintText: 'e.g., 5000',
                        prefixIcon: const Icon(Icons.savings),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // Savings tier
                    Text('Savings Tier:', style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.w600)),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Voluntary'),
                            selected: selectedTier == 'Voluntary',
                            onSelected: (_) => setModalState(() => selectedTier = 'Voluntary'),
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(
                              color: selectedTier == 'Voluntary' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Standing Order'),
                            selected: selectedTier == 'Standing Order',
                            onSelected: (_) => setModalState(() => selectedTier = 'Standing Order'),
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(
                              color: selectedTier == 'Standing Order' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),
                    
                    // If Standing Order, show amount and frequency
                    if (selectedTier == 'Standing Order') ...[
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Auto-deduct amount (KES)',
                          hintText: 'e.g., 500',
                          prefixIcon: const Icon(Icons.repeat),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 14),
                      
                      Text('Frequency:', style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      Wrap(
                        spacing: 8,
                        children: ['Daily', 'Weekly', 'Monthly'].map((freq) {
                          return ChoiceChip(
                            label: Text(freq),
                            selected: selectedFrequency == freq,
                            onSelected: (_) => setModalState(() => selectedFrequency = freq),
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(
                              color: selectedFrequency == freq ? Colors.white : Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                    ],
                    
                    SizedBox(height: isSmallScreen ? 14 : 16),
                    
                    // Create button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          final target = double.tryParse(_targetController.text.trim()) ?? 0.0;
                          final amount = selectedTier == 'Standing Order' 
                              ? (double.tryParse(_amountController.text.trim()) ?? 0.0)
                              : 0.0;
                          
                          if (name.isEmpty || target <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid name and target')),
                            );
                            return;
                          }
                          
                          if (selectedTier == 'Standing Order' && amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid auto-deduct amount')),
                            );
                            return;
                          }
                          
                          savings.addGoal(SavingsGoal(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            target: target,
                            isStandingOrder: selectedTier == 'Standing Order',
                            autoDeductAmount: amount,
                            frequency: selectedFrequency,
                          ));
                          
                          _nameController.clear();
                          _targetController.clear();
                          _amountController.clear();
                          Navigator.pop(ctx);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ ${selectedTier} goal created!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text('Create goal', style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PointsFromSavings extends StatelessWidget {
  final int points;
  final bool isSmallScreen;
  const _PointsFromSavings({required this.points, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium, color: Colors.white, size: isSmallScreen ? 28 : 32),
          ),
          SizedBox(width: isSmallScreen ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Points earned from savings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$points pts',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  final List<SavingsGoal> goals;
  final void Function(String id) onContribute;
  final bool isSmallScreen;
  const _GoalsList({required this.goals, required this.onContribute, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 10 : 12),
      itemBuilder: (_, i) {
        final goal = goals[i];
        final progress = goal.target == 0 ? 0.0 : goal.saved / goal.target;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    goal.isStandingOrder ? Icons.repeat : Icons.flag,
                    color: const Color(0xFF10B981),
                    size: isSmallScreen ? 22 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 15 : 16,
                          ),
                        ),
                        if (goal.isStandingOrder) ...[
                          SizedBox(height: 2),
                          Text(
                            'Auto: KES ${goal.autoDeductAmount.toStringAsFixed(0)} ${goal.frequency}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      'KES ${goal.saved.toStringAsFixed(0)} / ${goal.target.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                    ),
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                    labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: isSmallScreen ? 8 : 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(1)}% completed',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onContribute(goal.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 14 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                    ),
                    child: Text(
                      'Contribute',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
