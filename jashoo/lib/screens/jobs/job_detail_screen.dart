import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/jobs_provider.dart';
import '../../services/api_service.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final jobId = ModalRoute.of(context)?.settings.arguments as String?;
    final jobs = context.watch<JobsProvider>();
    final job = jobId != null ? jobs.getById(jobId) : null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job')),
        body: const Center(child: Text('Job not found')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(job.title, style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job details card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Text(
                          job.description,
                          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        Row(
                          children: [
                            Icon(Icons.location_on, size: isSmallScreen ? 18 : 20, color: Colors.grey[600]),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              job.location,
                              style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: isSmallScreen ? 18 : 20, color: const Color(0xFF10B981)),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              'KES ${job.priceKes.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Contact information section (shown after applying)
                if (job.status == JobStatus.inProgress || job.status == JobStatus.completed || job.status == JobStatus.paid)
                  Card(
                    elevation: 2,
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                          Text(
                            '📞 Contact Information',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 10 : 12),
                          
                          // Email
                          InkWell(
                            onTap: () => _launchEmail('poster@example.com'),
                            child: Row(
                              children: [
                                Icon(Icons.email, size: isSmallScreen ? 18 : 20, color: const Color(0xFF10B981)),
                                SizedBox(width: isSmallScreen ? 8 : 10),
                                Text(
                                  'poster@example.com',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.blue[700],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 10),
                          
                          // Phone
                          InkWell(
                            onTap: () => _launchPhone('+254712345678'),
                            child: Row(
                              children: [
                                Icon(Icons.phone, size: isSmallScreen ? 18 : 20, color: const Color(0xFF10B981)),
                                SizedBox(width: isSmallScreen ? 8 : 10),
                                Text(
                                  '+254 712 345 678',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.blue[700],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Action buttons
                Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                
                Wrap(
                  spacing: isSmallScreen ? 8 : 10,
                  runSpacing: isSmallScreen ? 8 : 10,
                  children: [
                    // Apply button (only if not started yet)
                    if (job.status == JobStatus.pending)
                      ElevatedButton.icon(
                        onPressed: _isApplying ? null : () => _applyForJob(context, jobs, job.id),
                        icon: Icon(_isApplying ? Icons.hourglass_empty : Icons.check_circle, size: isSmallScreen ? 18 : 20),
                        label: Text(_isApplying ? 'Applying...' : 'Apply', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    
                    // Complete button
                    if (job.status == JobStatus.inProgress)
                      ElevatedButton.icon(
                        onPressed: () => _completeJob(context, jobs, job.id),
                        icon: Icon(Icons.task_alt, size: isSmallScreen ? 18 : 20),
                        label: Text('Complete', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    
                    // Mark as Paid button
                    if (job.status == JobStatus.completed)
                      ElevatedButton.icon(
                        onPressed: () => _markAsPaid(context, jobs, job.id),
                        icon: Icon(Icons.payment, size: isSmallScreen ? 18 : 20),
                        label: Text('Mark as Paid', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    
                    // Leave Review button (only after job is paid)
                    if (job.status == JobStatus.paid)
                      ElevatedButton.icon(
              onPressed: () => _showReviewDialog(context, jobs, job.id),
                        icon: Icon(Icons.star_rate, size: isSmallScreen ? 18 : 20),
                        label: Text('Leave Review', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Job status indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(job.status)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(job.status), size: isSmallScreen ? 16 : 18, color: _getStatusColor(job.status)),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        'Status: ${_getStatusText(job.status)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(job.status),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _applyForJob(BuildContext context, JobsProvider jobs, String jobId) async {
    setState(() => _isApplying = true);
    try {
      jobs.updateStatus(jobId, JobStatus.inProgress);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully applied! Contact info is now visible.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }
  
  Future<void> _completeJob(BuildContext context, JobsProvider jobs, String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Job'),
        content: const Text('Mark this job as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      jobs.updateStatus(jobId, JobStatus.completed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job marked as completed!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _markAsPaid(BuildContext context, JobsProvider jobs, String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Confirm that payment has been received?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      jobs.updateStatus(jobId, JobStatus.paid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job marked as paid!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  void _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Colors.grey;
      case JobStatus.inProgress:
        return const Color(0xFF10B981);
      case JobStatus.completed:
        return Colors.blue;
      case JobStatus.paid:
        return Colors.orange;
    }
  }
  
  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Icons.pending_outlined;
      case JobStatus.inProgress:
        return Icons.work_outline;
      case JobStatus.completed:
        return Icons.check_circle_outline;
      case JobStatus.paid:
        return Icons.payment;
    }
  }
  
  String _getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'Available';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.paid:
        return 'Paid';
    }
  }
}

Future<void> _showReviewDialog(BuildContext context, JobsProvider jobs, String jobId) async {
  int selectedRating = 0;
  final reviewController = TextEditingController();
  bool isSubmitting = false;
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 700;
  
  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Leave Review', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        content: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating (0-5 stars)',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              
              // Star rating selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = index),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6),
                      child: Column(
        children: [
                          Icon(
                            index == 0 ? Icons.cancel_outlined : (selectedRating >= index ? Icons.star : Icons.star_border),
                            size: isSmallScreen ? 32 : 36,
                            color: index == 0 ? Colors.grey : (selectedRating >= index ? Colors.amber : Colors.grey[400]),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            index == 0 ? '0' : '$index',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: selectedRating == index ? FontWeight.bold : FontWeight.normal,
                              color: selectedRating == index ? const Color(0xFF10B981) : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              Text(
                'Comment',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              
          TextField(
                controller: reviewController,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                ),
                maxLines: 3,
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
          ),
          ElevatedButton(
            onPressed: isSubmitting ? null : () async {
              if (selectedRating < 0 || selectedRating > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a rating between 0-5 stars'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              setState(() => isSubmitting = true);
              
              try {
                // Submit review to provider (which calls backend)
                jobs.addReview(jobId, selectedRating.toDouble(), reviewController.text.trim());
                
                // Also submit directly to backend
                try {
                  final apiService = ApiService();
                  await apiService.submitRating(
                    jobId: jobId,
                    rating: selectedRating.toDouble(),
                    comment: reviewController.text.trim(),
                  );
                } catch (e) {
                  print('Backend submission failed (non-critical): $e');
                }
                
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        const Text('✅ Review submitted successfully!'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                setState(() => isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error submitting review: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: isSubmitting
                ? SizedBox(
                    width: isSmallScreen ? 16 : 20,
                    height: isSmallScreen ? 16 : 20,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Submit', style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
          ),
        ],
      ),
    ),
  );
}

