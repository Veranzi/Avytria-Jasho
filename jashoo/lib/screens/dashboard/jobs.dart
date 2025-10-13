import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        title: Image.asset('assets/logo1.png', height: isSmallScreen ? 24 : 28),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, size: isSmallScreen ? 22 : 24),
            onPressed: () => Navigator.pushNamed(context, '/postJob'),
            tooltip: 'Post Job',
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Available Gigs",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 10,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: isSmallScreen ? 14 : 16,
                      color: const Color(0xFF10B981),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 6),
                    Text(
                      "3 Jobs",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),

          // Sample job cards
          _buildJobCard(
            context,
            id: 'job-1',
            title: "Boda Boda Delivery",
            description: "Earn by delivering parcels within Nairobi.",
            price: "KES 500/trip",
            isSmallScreen: isSmallScreen,
          ),
          _buildJobCard(
            context,
            id: 'job-2',
            title: "Mama Fua – Cleaning Job",
            description: "House cleaning job, flexible hours.",
            price: "KES 800/day",
            isSmallScreen: isSmallScreen,
          ),
          _buildJobCard(
            context,
            id: 'job-3',
            title: "Handyman Work",
            description: "Fixing small household repairs.",
            price: "KES 1000/job",
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  /// Job Card Widget
  Widget _buildJobCard(
    BuildContext context, {
    required String id,
    required String title,
    required String description,
    required String price,
    required bool isSmallScreen,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
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
                    Icons.work,
                    color: const Color(0xFF10B981),
                    size: isSmallScreen ? 20 : 22,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Text(
              description,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/jobDetail', arguments: id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "View Details",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
