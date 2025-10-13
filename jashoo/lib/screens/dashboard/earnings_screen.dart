import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyEarningsPage extends StatefulWidget {
  const MyEarningsPage({super.key});

  @override
  State<MyEarningsPage> createState() => _MyEarningsPageState();
}

class _MyEarningsPageState extends State<MyEarningsPage> {
  String _selectedPeriod = 'Weekly'; // Daily, Weekly, Monthly

  // Sample data - in production, fetch from backend based on period
  final Map<String, List<FlSpot>> _earningsData = {
    'Daily': [
      FlSpot(1, 500),
      FlSpot(2, 800),
      FlSpot(3, 600),
      FlSpot(4, 1200),
      FlSpot(5, 900),
      FlSpot(6, 1100),
      FlSpot(7, 1500),
    ],
    'Weekly': [
      FlSpot(1, 5000),
      FlSpot(2, 6500),
      FlSpot(3, 4800),
      FlSpot(4, 7200),
    ],
    'Monthly': [
      FlSpot(1, 15000),
      FlSpot(2, 18000),
      FlSpot(3, 22000),
      FlSpot(4, 19500),
      FlSpot(5, 25000),
      FlSpot(6, 21000),
    ],
  };

  final Map<String, List<FlSpot>> _expenditureData = {
    'Daily': [
      FlSpot(1, 300),
      FlSpot(2, 500),
      FlSpot(3, 400),
      FlSpot(4, 800),
      FlSpot(5, 600),
      FlSpot(6, 700),
      FlSpot(7, 900),
    ],
    'Weekly': [
      FlSpot(1, 3500),
      FlSpot(2, 4200),
      FlSpot(3, 3800),
      FlSpot(4, 5500),
    ],
    'Monthly': [
      FlSpot(1, 12000),
      FlSpot(2, 14000),
      FlSpot(3, 16500),
      FlSpot(4, 15000),
      FlSpot(5, 18000),
      FlSpot(6, 16000),
    ],
  };

  double get _totalEarnings {
    return _earningsData[_selectedPeriod]!.fold(0, (sum, spot) => sum + spot.y);
  }

  double get _totalExpenditure {
    return _expenditureData[_selectedPeriod]!.fold(0, (sum, spot) => sum + spot.y);
  }

  double get _netBalance => _totalEarnings - _totalExpenditure;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('Earnings & Expenditure', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period selector
            _buildPeriodSelector(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // Summary cards
            _buildSummaryCards(isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 24),

            // Chart title
            Text(
              'Earnings vs Expenditure',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Line chart
            _buildLineChart(isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 24),

            // Legend
            _buildLegend(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
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

  Widget _buildSummaryCards(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Earnings',
            'KES ${_totalEarnings.toStringAsFixed(0)}',
            Colors.green,
            Icons.trending_up,
            isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildSummaryCard(
            'Expenditure',
            'KES ${_totalExpenditure.toStringAsFixed(0)}',
            Colors.red,
            Icons.trending_down,
            isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildSummaryCard(
            'Net',
            'KES ${_netBalance.toStringAsFixed(0)}',
            _netBalance >= 0 ? const Color(0xFF10B981) : Colors.orange,
            Icons.account_balance_wallet,
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 24 : 28),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 250 : 300,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getInterval(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                _getXAxisLabel(),
                style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey[600]),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isSmallScreen ? 28 : 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'Amount (KES)',
                style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey[600]),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isSmallScreen ? 50 : 60,
                interval: _getInterval(),
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey[600]),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: _earningsData[_selectedPeriod]!.first.x,
          maxX: _earningsData[_selectedPeriod]!.last.x,
          minY: 0,
          maxY: _getMaxY(),
          lineBarsData: [
            // Earnings line (green)
            LineChartBarData(
              spots: _earningsData[_selectedPeriod]!,
              isCurved: true,
              color: const Color(0xFF10B981),
              barWidth: isSmallScreen ? 3 : 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: isSmallScreen ? 4 : 5,
                    color: const Color(0xFF10B981),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF10B981).withOpacity(0.1),
              ),
            ),
            // Expenditure line (red)
            LineChartBarData(
              spots: _expenditureData[_selectedPeriod]!,
              isCurved: true,
              color: Colors.red,
              barWidth: isSmallScreen ? 3 : 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: isSmallScreen ? 4 : 5,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black87,
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final isEarnings = barSpot.barIndex == 0;
                  return LineTooltipItem(
                    '${isEarnings ? 'Earnings' : 'Expenditure'}\nKES ${barSpot.y.toStringAsFixed(0)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Earnings', const Color(0xFF10B981), isSmallScreen),
        SizedBox(width: isSmallScreen ? 20 : 24),
        _buildLegendItem('Expenditure', Colors.red, isSmallScreen),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 16 : 20,
          height: isSmallScreen ? 3 : 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  double _getMaxY() {
    final maxEarnings = _earningsData[_selectedPeriod]!.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final maxExpenditure = _expenditureData[_selectedPeriod]!.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return (maxEarnings > maxExpenditure ? maxEarnings : maxExpenditure) * 1.2;
  }

  double _getInterval() {
    final maxY = _getMaxY();
    return maxY / 5;
  }

  String _getXAxisLabel() {
    switch (_selectedPeriod) {
      case 'Daily':
        return 'Day of Week';
      case 'Weekly':
        return 'Week of Month';
      case 'Monthly':
        return 'Month';
      default:
        return 'Period';
    }
  }
}
