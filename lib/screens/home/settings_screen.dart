import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_page.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const SettingsScreen({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await GoogleSignIn.instance.signOut();
      }
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  /// Recursively deletes all files and subfolders in a Firebase Storage reference
  Future<void> _deleteStorageFolderRecursively(Reference ref) async {
    final listResult = await ref.listAll();
    
    // Delete all files in this folder
    for (var item in listResult.items) {
      await item.delete();
    }
    
    // Recursively delete all subfolders
    for (var prefix in listResult.prefixes) {
      await _deleteStorageFolderRecursively(prefix);
    }
  }

  Future<void> _handleDeleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = widget.user.uid;

      // Delete all user files from Storage recursively
      try {
        final storageRef = FirebaseStorage.instance.ref().child('users/$userId');
        await _deleteStorageFolderRecursively(storageRef);
      } catch (_) {
        // Continue with account deletion even if storage fails
      }

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      // Delete Firebase Auth account
      await widget.user.delete();

      // Sign out
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await GoogleSignIn.instance.signOut();
      }
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Show farewell dialog before navigating to login
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Color(0xFF0039A6),
                ),
                const SizedBox(height: 16),
                const Text(
                  "We're sorry to see you go.",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0039A6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account has been deleted successfully.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0039A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Goodbye'),
                  ),
                ),
              ],
            ),
          ),
        );

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0039A6),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0039A6)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email
                        _buildSettingsItem(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: widget.user.email ?? 'No email',
                          showChevron: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Actions Section
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Logout
                        _buildActionItem(
                          icon: Icons.logout,
                          label: 'Logout',
                          color: const Color(0xFF0039A6),
                          onTap: _handleLogout,
                        ),
                        const Divider(height: 1, indent: 56),
                        // Delete Account
                        _buildActionItem(
                          icon: Icons.delete_forever,
                          label: 'Delete Account',
                          color: Colors.red,
                          onTap: _handleDeleteAccount,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App info
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'Date',
                                style: TextStyle(color: Colors.grey),
                              ),
                              TextSpan(
                                text: 'Blue',
                                style: TextStyle(color: Color(0xFF0039A6)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String value,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0039A6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0039A6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
