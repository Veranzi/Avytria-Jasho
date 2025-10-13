import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/ai_provider.dart';
import '../../providers/wallet_provider.dart';
import 'dart:async';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  String _selectedPeriod = 'Weekly'; // Daily, Weekly, Monthly
  int _touchedIndex = -1;
  bool _balanceVisible = false; // Mask balance by default
  Timer? _hideTimer; // Timer for auto-hiding balance
  
  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
  
  void _toggleBalanceVisibility() {
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
    
    // Auto-hide after 10 seconds if visible
    if (_balanceVisible) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _balanceVisible = false;
          });
        }
      });
    }
  }

  // Sample expenditure data that changes based on period
  Map<String, Map<String, double>> _expenditureByPeriod = {
    'Daily': {
      'Food': 350,
      'Transport': 200,
      'Water': 150,
      'Internet': 180,
      'Other': 120,
    },
    'Weekly': {
      'Food': 2450,
      'Electricity': 1400,
      'Water': 1050,
      'Internet': 1260,
      'Other': 840,
    },
    'Monthly': {
      'Food': 10000,
      'Rent': 15000,
      'Electricity': 5000,
      'Water': 3000,
      'Internet': 4000,
      'Transport': 8000,
      'Other': 5000,
    },
  };

  Map<String, double> get _currentExpenditure => _expenditureByPeriod[_selectedPeriod]!;
  double get _totalExpenditure => _currentExpenditure.values.reduce((a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Insights', style: TextStyle(fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with AI branding
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.psychology_rounded, color: Colors.white, size: isSmallScreen ? 32 : 36),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jasho AI', style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Text('Personalized insights powered by machine learning', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isSmallScreen ? 12 : 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 18 : 22),
              
              // Wallet Balance Card with masking
              _buildWalletBalanceCard(context, isSmallScreen),
              SizedBox(height: isSmallScreen ? 18 : 22),
              
              // Period selector
              _buildPeriodSelector(isSmallScreen),
              SizedBox(height: isSmallScreen ? 18 : 22),

              // Expenditure pie chart with labels
              _buildExpenditureChart(isSmallScreen),
              SizedBox(height: isSmallScreen ? 18 : 22),

              // AI Predictions
              Text('AI Predictions', style: TextStyle(fontSize: isSmallScreen ? 17 : 19, fontWeight: FontWeight.bold)),
              SizedBox(height: isSmallScreen ? 10 : 12),
              _predictionCard(isEnglish ? 'You earned 20% more than last week.' : 'Ulipata 20% zaidi kuliko wiki iliyopita.', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8 : 10),
              _predictionCard(isEnglish ? 'Cleaning jobs rise on weekends.' : 'Kazi za usafi huongezeka wikendi.', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8 : 10),
              _predictionCard(isEnglish ? 'Save KES 500 to reach your goal.' : 'Weka KES 500 kufikia lengo.', isSmallScreen),
              
              SizedBox(height: isSmallScreen ? 18 : 22),

              // AI Suggestions
              if (ai.suggestions.isNotEmpty) ...[
                Text('Personalized Suggestions', style: TextStyle(fontSize: isSmallScreen ? 17 : 19, fontWeight: FontWeight.bold)),
                SizedBox(height: isSmallScreen ? 10 : 12),
                ...ai.suggestions.map((s) {
                  final text = isEnglish ? s.messageEn : s.messageSw;
                  return Card(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.lightbulb_outline, color: const Color(0xFF10B981)),
                      title: Text(text, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenditureChart(bool isSmallScreen) {
    final colors = [Colors.orange, const Color(0xFF10B981), Colors.lightBlue, Colors.deepPurple, Colors.teal, Colors.amber, Colors.grey];
    final categories = _currentExpenditure.keys.toList();
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Expenditure ($_selectedPeriod)', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold)),
              Text('KES ${_totalExpenditure.toStringAsFixed(0)}', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
            ],
          ),
          SizedBox(height: isSmallScreen ? 18 : 22),
          
          SizedBox(
            height: isSmallScreen ? 220 : 250,
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: isSmallScreen ? 35 : 40,
                      sections: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final value = _currentExpenditure[category]!;
                        final isTouched = index == _touchedIndex;
                        final radius = isTouched ? (isSmallScreen ? 55.0 : 60.0) : (isSmallScreen ? 50.0 : 55.0);
                        final percentage = (value / _totalExpenditure * 100).toStringAsFixed(1);
                        
                        return PieChartSectionData(
                          value: value,
                          color: colors[index % colors.length],
                          title: '$percentage%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? (isSmallScreen ? 12 : 13) : (isSmallScreen ? 10 : 11),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                // Legend with amounts
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final value = _currentExpenditure[category]!;
                        return _legend(
                          color: colors[index % colors.length],
                          label: category,
                          amount: 'KES ${value.toStringAsFixed(0)}',
                          isSmallScreen: isSmallScreen,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionCard(String text, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.trending_up, color: const Color(0xFF10B981), size: isSmallScreen ? 22 : 24),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: isSmallScreen ? 13 : 14, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _legend({required Color color, required String label, required String amount, required bool isSmallScreen}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 5 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 12 : 14,
                height: isSmallScreen ? 12 : 14,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(height: 2),
          Padding(
            padding: EdgeInsets.only(left: isSmallScreen ? 18 : 22),
            child: Text(amount, style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWalletBalanceCard(BuildContext context, bool isSmallScreen) {
    final wallet = context.watch<WalletProvider>();
    final kesBalance = wallet.kesBalance;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                _balanceVisible ? 'KES ${kesBalance.toStringAsFixed(2)}' : 'KES ••••••',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_balanceVisible) ...[
                SizedBox(height: 4),
                Text(
                  'Auto-hides in 10s',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isSmallScreen ? 10 : 11,
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            icon: Icon(
              _balanceVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
            onPressed: _toggleBalanceVisibility,
            tooltip: _balanceVisible ? 'Hide balance' : 'Show balance',
          ),
        ],
      ),
    );
  }
}
