import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _idType;
  final _idNumberController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Verification', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
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
                              'Complete KYC verification to post jobs and access premium features.',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  
                  // Document type dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _idType,
                    items: const [
                      DropdownMenuItem(value: 'ID', child: Text('National ID')),
                      DropdownMenuItem(value: 'PASSPORT', child: Text('Passport')),
                    ],
                    onChanged: (v) => setState(() => _idType = v),
                    decoration: InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14,
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    validator: (v) => v == null ? 'Please select a document type' : null,
                  ),
                  SizedBox(height: isSmallScreen ? 14 : 16),
                  
                  // Document number field
                  TextFormField(
                    controller: _idNumberController,
                    decoration: InputDecoration(
                      labelText: 'Document Number',
                      hintText: 'Enter your ID or Passport number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 14,
                        vertical: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter document number' : null,
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () async {
                      if (!_formKey.currentState!.validate()) return;
                      
                      setState(() => _isSubmitting = true);
                      
                      try {
                        await context.read<UserProvider>().completeKyc(
                              idType: _idType!,
                              idNumber: _idNumberController.text.trim(),
                            );
                        
                        if (mounted) {
                          // Show success dialog
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: const Color(0xFF10B981),
                                    size: isSmallScreen ? 56 : 64,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  Text(
                                    'KYC Submitted!',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 20 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Your KYC verification has been successfully submitted. You can now post jobs and access all features.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: isSmallScreen ? 13 : 14, height: 1.5),
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Go back to previous screen
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 28 : 32,
                                      vertical: isSmallScreen ? 12 : 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('Done', style: TextStyle(fontSize: isSmallScreen ? 15 : 16)),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => _isSubmitting = false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: isSmallScreen ? 20 : 22,
                            width: isSmallScreen ? 20 : 22,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit KYC',
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

