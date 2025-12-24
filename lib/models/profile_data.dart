import 'package:flutter/material.dart';

/// Model representing a user's profile data for display in profile cards.
/// This model handles the transformation from Firestore data to display-ready format.
class ProfileData {
  final String id;
  final String firstName;
  final int? age;
  final String? campus;
  final String? pronouns;
  final String? sexuality;
  final String? height;
  final int? heightCm;
  final String? hometown;
  final String? workplace;
  final String? jobTitle;
  final List<String>? ethnicities;
  final List<String>? religiousBeliefs;
  final String? intentions;
  final String? drinkingStatus;
  final String? smokingStatus;
  final String? weedStatus;
  final String? drugStatus;
  final String? children;
  final List<String> mediaUrls;
  final List<ProfilePrompt> prompts;
  
  // Visibility flags
  final bool showHeight;
  final bool showHometown;
  final bool showWork;
  final bool showEthnicity;
  final bool showReligiousBeliefs;
  final bool showIntentions;
  final bool showSubstanceUse;
  final bool showChildren;

  const ProfileData({
    required this.id,
    required this.firstName,
    this.age,
    this.campus,
    this.pronouns,
    this.sexuality,
    this.height,
    this.heightCm,
    this.hometown,
    this.workplace,
    this.jobTitle,
    this.ethnicities,
    this.religiousBeliefs,
    this.intentions,
    this.drinkingStatus,
    this.smokingStatus,
    this.weedStatus,
    this.drugStatus,
    this.children,
    this.mediaUrls = const [],
    this.prompts = const [],
    this.showHeight = true,
    this.showHometown = true,
    this.showWork = true,
    this.showEthnicity = true,
    this.showReligiousBeliefs = true,
    this.showIntentions = true,
    this.showSubstanceUse = true,
    this.showChildren = true,
  });

  /// Creates a ProfileData from Firestore document data
  factory ProfileData.fromFirestore(String id, Map<String, dynamic> data) {
    // Parse birthday to age
    int? age;
    if (data['birthday'] != null) {
      final birthday = (data['birthday'] as dynamic).toDate();
      age = _calculateAge(birthday);
    }

    // Parse prompts
    List<ProfilePrompt> prompts = [];
    if (data['prompts'] != null) {
      prompts = (data['prompts'] as List)
          .map((p) => ProfilePrompt.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    // Parse media URLs
    List<String> mediaUrls = [];
    if (data['mediaUrls'] != null) {
      mediaUrls = List<String>.from(data['mediaUrls']);
    }

    // Parse height
    String? height;
    if (data['height'] != null) {
      if (data['height'] is String) {
        height = data['height'];
      } else if (data['height'] is int) {
        height = '${data['height']} cm';
      }
    }

    // Parse ethnicities
    List<String>? ethnicities;
    if (data['ethnicities'] != null) {
      ethnicities = List<String>.from(data['ethnicities']);
    }

    // Parse religious beliefs
    List<String>? religiousBeliefs;
    if (data['religiousBeliefs'] != null) {
      if (data['religiousBeliefs'] is List) {
        religiousBeliefs = List<String>.from(data['religiousBeliefs']);
      } else if (data['religiousBeliefs'] is String) {
        religiousBeliefs = [data['religiousBeliefs']];
      }
    }

    return ProfileData(
      id: id,
      firstName: data['firstName'] ?? 'Unknown',
      age: age,
      campus: data['campus'],
      pronouns: data['pronouns'],
      sexuality: data['sexuality'],
      height: height,
      heightCm: data['heightCm'],
      hometown: data['hometown'],
      workplace: data['workplace'],
      jobTitle: data['jobTitle'],
      ethnicities: ethnicities,
      religiousBeliefs: religiousBeliefs,
      intentions: data['intentions'],
      drinkingStatus: data['drinkingStatus'],
      smokingStatus: data['smokingStatus'],
      weedStatus: data['weedStatus'],
      drugStatus: data['drugStatus'],
      children: data['children'],
      mediaUrls: mediaUrls,
      prompts: prompts,
      showHeight: data['showHeightOnProfile'] ?? true,
      showHometown: data['showHometownOnProfile'] ?? true,
      showWork: data['showWorkOnProfile'] ?? true,
      showEthnicity: data['showEthnicityOnProfile'] ?? true,
      showReligiousBeliefs: data['showReligiousBeliefOnProfile'] ?? true,
      showIntentions: data['showIntentionsOnProfile'] ?? true,
      showSubstanceUse: data['showSubstanceUseOnProfile'] ?? true,
      showChildren: data['showChildrenOnProfile'] ?? true,
    );
  }

  static int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Get formatted work string
  String? get formattedWork {
    if (workplace != null && jobTitle != null) {
      return '$jobTitle at $workplace';
    } else if (workplace != null) {
      return workplace;
    } else if (jobTitle != null) {
      return jobTitle;
    }
    return null;
  }

  /// Get formatted intentions label
  String? get intentionsLabel {
    switch (intentions) {
      case 'long_term':
        return 'Long-term relationship';
      case 'long_open_to_short':
        return 'Long-term, open to short';
      case 'short_open_to_long':
        return 'Short-term, open to long';
      case 'short_term':
        return 'Short-term fun';
      case 'figuring_out':
        return 'Still figuring it out';
      default:
        return intentions;
    }
  }

  /// Get visible vitals for display
  List<ProfileVital> get visibleVitals {
    final vitals = <ProfileVital>[];

    if (showHeight && height != null) {
      vitals.add(ProfileVital(
        icon: Icons.height,
        label: 'Height',
        value: height!,
      ));
    }

    if (showHometown && hometown != null) {
      vitals.add(ProfileVital(
        icon: Icons.location_on_outlined,
        label: 'Hometown',
        value: hometown!,
      ));
    }

    if (showWork && formattedWork != null) {
      vitals.add(ProfileVital(
        icon: Icons.work_outline,
        label: 'Work',
        value: formattedWork!,
      ));
    }

    if (showEthnicity && ethnicities != null && ethnicities!.isNotEmpty) {
      vitals.add(ProfileVital(
        icon: Icons.public,
        label: 'Ethnicity',
        value: _formatEthnicities(ethnicities!),
      ));
    }

    if (showReligiousBeliefs && religiousBeliefs != null && religiousBeliefs!.isNotEmpty) {
      vitals.add(ProfileVital(
        icon: Icons.auto_awesome,
        label: 'Religion',
        value: religiousBeliefs!.join(', '),
      ));
    }

    if (showIntentions && intentionsLabel != null) {
      vitals.add(ProfileVital(
        icon: Icons.favorite_border,
        label: 'Looking for',
        value: intentionsLabel!,
      ));
    }

    if (showChildren && children != null) {
      vitals.add(ProfileVital(
        icon: Icons.child_care,
        label: 'Children',
        value: children!,
      ));
    }

    if (showSubstanceUse) {
      if (drinkingStatus != null && drinkingStatus != 'Prefer not to say') {
        vitals.add(ProfileVital(
          icon: Icons.local_bar,
          label: 'Drinking',
          value: drinkingStatus!,
        ));
      }
      if (smokingStatus != null && smokingStatus != 'Prefer not to say') {
        vitals.add(ProfileVital(
          icon: Icons.smoking_rooms,
          label: 'Smoking',
          value: smokingStatus!,
        ));
      }
    }

    return vitals;
  }

  String _formatEthnicities(List<String> ethnicities) {
    return ethnicities.map((e) {
      switch (e) {
        case 'asian':
          return 'Asian';
        case 'black':
          return 'Black';
        case 'hispanic':
          return 'Hispanic/Latino';
        case 'indigenous':
          return 'Indigenous';
        case 'middle_eastern':
          return 'Middle Eastern';
        case 'pacific_islander':
          return 'Pacific Islander';
        case 'south_asian':
          return 'South Asian';
        case 'white':
          return 'White';
        default:
          return e;
      }
    }).join(', ');
  }
}

/// Represents a profile prompt with question and answer
class ProfilePrompt {
  final String id;
  final String category;
  final String question;
  final String text;

  const ProfilePrompt({
    required this.id,
    required this.category,
    required this.question,
    required this.text,
  });

  factory ProfilePrompt.fromMap(Map<String, dynamic> map) {
    // Handle both new format (with question field) and legacy format (question in id)
    String question = map['question'] ?? '';
    if (question.isEmpty && map['id'] != null) {
      // Legacy fallback: extract question from id
      final parts = (map['id'] as String).split('-');
      if (parts.length > 1) {
        question = parts.sublist(1).join('-');
      }
    }

    return ProfilePrompt(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      question: question,
      text: map['text'] ?? '',
    );
  }
}

/// Represents a single vital/fact about a user
class ProfileVital {
  final IconData icon;
  final String label;
  final String value;

  const ProfileVital({
    required this.icon,
    required this.label,
    required this.value,
  });
}
