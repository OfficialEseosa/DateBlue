import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profile_data.dart';
import '../../theme/date_blue_theme.dart';
import '../../widgets/profile/profile_card.dart';
import 'edit_profile/edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const ProfilePage({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileData _profileData;

  @override
  void initState() {
    super.initState();
    _profileData = ProfileData.fromFirestore(
      widget.user.uid,
      widget.userData ?? {},
    );
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update profile data if userData changes
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _profileData = ProfileData.fromFirestore(
          widget.user.uid,
          widget.userData ?? {},
        );
      });
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          user: widget.user,
          userData: widget.userData,
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: widget.user,
          userData: widget.userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DateBlueTheme.scaffoldBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Main Profile Card - uses reusable ProfileCard widget
              Expanded(
                child: ProfileCard(
                  profile: _profileData,
                  isOwnProfile: true,
                  onSettingsTap: _navigateToSettings,
                  onEditTap: _navigateToEditProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
