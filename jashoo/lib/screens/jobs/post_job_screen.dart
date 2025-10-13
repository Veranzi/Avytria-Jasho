import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _loc = TextEditingController();
  final _price = TextEditingController();
  bool _isPosting = false;
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkKycStatus();
    });
  }

  Future<void> _checkKycStatus() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.profile;
    
    if (user?.isKycComplete != true) {
      // User hasn't completed KYC - show dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 12),
              Text('KYC Required'),
            ],
          ),
          content: const Text(
            'You need to complete KYC verification before posting jobs. This helps us maintain a safe and trusted marketplace.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(context, '/kyc').then((_) {
                  // Check again after KYC screen
                  _checkKycStatus();
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Complete KYC'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isPosting = true);
    
    try {
      final price = double.parse(_price.text.trim());
      final jobTitle = _title.text.trim();
      final jobDescription = _desc.text.trim();
      final jobLocation = _loc.text.trim();
      
      // Step 1: Create job (marked as pending)
      final jobId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Step 2: Submit to AI for verification (simulated)
      final aiVerified = await _simulateAIVerification(jobTitle, jobDescription);
      
      if (!aiVerified) {
        // Job rejected by AI
        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Text('Job Not Approved'),
                ],
              ),
              content: const Text(
                'Our AI system detected potential issues with your job posting. Please ensure your job description is legitimate and follows our community guidelines.',
                style: TextStyle(height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Understood'),
                ),
              ],
            ),
          );
          setState(() => _isPosting = false);
        }
        return;
      }
      
      // Step 3: Job approved - post it
      if (mounted) {
        context.read<JobsProvider>().postJob(JobItem(
          id: jobId,
          title: jobTitle,
          description: jobDescription,
          location: jobLocation,
          priceKes: price,
        ));
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('✅ Job posted successfully after AI verification!')),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isPosting = false);
      }
    }
  }
  
  Future<bool> _simulateAIVerification(String title, String description) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple rule-based verification (in production, use real ML model)
    final suspiciousKeywords = [
      'scam', 'fraud', 'fake', 'illegal', 'drugs', 'weapons', 
      'money laundering', 'pyramid', 'ponzi', 'get rich quick'
    ];
    
    final combinedText = '$title $description'.toLowerCase();
    for (final keyword in suspiciousKeywords) {
      if (combinedText.contains(keyword)) {
        return false; // Reject
      }
    }
    
    // Additional checks
    if (title.length < 5 || description.length < 20) {
      return false; // Too short, likely spam
    }
    
    return true; // Approved
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    if (_isVerifying) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Post a Job', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
          backgroundColor: const Color(0xFF10B981),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a Job', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Card(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 14.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: const Color(0xFF10B981), size: isSmallScreen ? 22 : 24),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Expanded(
                            child: Text(
                              'Your job will be reviewed by our AI system to ensure it meets community guidelines.',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Job title
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: 'Job Title',
                      hintText: 'e.g., Boda Boda Delivery',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14,
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter job title' : null,
                  ),
                  SizedBox(height: isSmallScreen ? 14 : 16),
                  
                  // Description
                  TextFormField(
                    controller: _desc,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the job in detail...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter description' : null,
                  ),
                  SizedBox(height: isSmallScreen ? 14 : 16),
                  
                  // Location
                  TextFormField(
                    controller: _loc,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., Nairobi CBD',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14,
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter location' : null,
                  ),
                  SizedBox(height: isSmallScreen ? 14 : 16),
                  
                  // Price
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price (KES)',
                      hintText: 'e.g., 500',
                      prefix: const Text('KES '),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14,
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter price';
                      final price = double.tryParse(v);
                      if (price == null || price <= 0) return 'Please enter valid price';
                      return null;
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  
                  // Post button
                  ElevatedButton(
                    onPressed: _isPosting ? null : _postJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isPosting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: isSmallScreen ? 18 : 20,
                                width: isSmallScreen ? 18 : 20,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 12),
                              Text(
                                'Verifying with AI...',
                                style: TextStyle(fontSize: isSmallScreen ? 15 : 16),
                              ),
                            ],
                          )
                        : Text(
                            'Post Job',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

