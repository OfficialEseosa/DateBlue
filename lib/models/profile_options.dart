import 'package:flutter/material.dart';

/// Centralized profile options with values and labels
/// Used by both onboarding and edit profile screens
class ProfileOptions {
  ProfileOptions._();

  // ===================
  // ETHNICITY OPTIONS
  // ===================
  static const List<Map<String, dynamic>> ethnicityOptions = [
    {'value': 'asian', 'label': 'Asian'},
    {'value': 'black', 'label': 'Black / African Descent'},
    {'value': 'hispanic', 'label': 'Hispanic / Latino'},
    {'value': 'indigenous', 'label': 'Indigenous / Native'},
    {'value': 'middle_eastern', 'label': 'Middle Eastern'},
    {'value': 'pacific_islander', 'label': 'Pacific Islander'},
    {'value': 'south_asian', 'label': 'South Asian'},
    {'value': 'white', 'label': 'White / Caucasian'},
    {'value': 'other', 'label': 'Other'},
  ];

  static String getEthnicityLabel(String value) {
    return ethnicityOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  static String formatEthnicityList(List<String>? values) {
    if (values == null || values.isEmpty) return 'Add';
    return values.map(getEthnicityLabel).join(', ');
  }

  // ===================
  // DATING PREFERENCES
  // ===================
  static const List<Map<String, dynamic>> datingPreferenceOptions = [
    {'value': 'men', 'label': 'Men', 'icon': Icons.male},
    {'value': 'women', 'label': 'Women', 'icon': Icons.female},
    {'value': 'nonbinary', 'label': 'Non-binary', 'icon': Icons.transgender},
  ];

  static String getDatingPrefLabel(String value) {
    return datingPreferenceOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  static String formatDatingPrefList(List<String>? values) {
    if (values == null || values.isEmpty) return 'Add';
    return values.map(getDatingPrefLabel).join(', ');
  }

  // ===================
  // GENDER OPTIONS
  // ===================
  static const List<Map<String, dynamic>> genderOptions = [
    {'value': 'man', 'label': 'Man', 'icon': Icons.male},
    {'value': 'woman', 'label': 'Woman', 'icon': Icons.female},
    {'value': 'nonbinary', 'label': 'Non-binary', 'icon': Icons.transgender},
  ];

  static String getGenderLabel(String? value) {
    if (value == null) return 'Add';
    return genderOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  // ===================
  // PRONOUN OPTIONS
  // ===================
  static const List<Map<String, dynamic>> pronounOptions = [
    {'value': 'he/him', 'label': 'He/Him', 'icon': Icons.person},
    {'value': 'she/her', 'label': 'She/Her', 'icon': Icons.person_outline},
    {'value': 'they/them', 'label': 'They/Them', 'icon': Icons.people_outline},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  static String getPronounLabel(String? value) {
    if (value == null) return '';
    return pronounOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  static String formatGenderPronouns(String? gender, String? pronouns) {
    final g = getGenderLabel(gender);
    final p = getPronounLabel(pronouns);
    if (g == 'Add' && p.isEmpty) return 'Add';
    if (p.isEmpty) return g;
    return '$g ($p)';
  }

  // ===================
  // SEXUALITY OPTIONS
  // ===================
  static const List<Map<String, dynamic>> sexualityOptions = [
    {'value': 'straight', 'label': 'Straight', 'icon': Icons.favorite},
    {'value': 'gay', 'label': 'Gay', 'icon': Icons.flag},
    {'value': 'lesbian', 'label': 'Lesbian', 'icon': Icons.flag},
    {'value': 'bisexual', 'label': 'Bisexual', 'icon': Icons.favorite_border},
    {'value': 'pansexual', 'label': 'Pansexual', 'icon': Icons.favorite},
    {'value': 'asexual', 'label': 'Asexual', 'icon': Icons.favorite_outline},
    {'value': 'queer', 'label': 'Queer', 'icon': Icons.auto_awesome},
    {'value': 'questioning', 'label': 'Questioning', 'icon': Icons.help_outline},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  static String getSexualityLabel(String? value) {
    if (value == null) return 'Add';
    return sexualityOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  // ===================
  // INTENTIONS OPTIONS
  // ===================
  static const List<Map<String, dynamic>> intentionOptions = [
    {'value': 'long_term', 'label': 'Long-term relationship', 'icon': Icons.favorite, 'desc': 'Looking for something serious'},
    {'value': 'long_open_to_short', 'label': 'Long-term, open to short', 'icon': Icons.favorite_border, 'desc': 'Prefer long-term but flexible'},
    {'value': 'short_open_to_long', 'label': 'Short-term, open to long', 'icon': Icons.auto_awesome, 'desc': 'Starting casual, open to more'},
    {'value': 'short_term', 'label': 'Short-term fun', 'icon': Icons.whatshot, 'desc': 'Keeping things casual'},
    {'value': 'figuring_out', 'label': 'Still figuring it out', 'icon': Icons.help_outline, 'desc': 'Exploring what I want'},
  ];

  static String getIntentionLabel(String? value) {
    if (value == null) return 'Add';
    return intentionOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  // ===================
  // RELIGIOUS BELIEFS
  // ===================
  static const List<Map<String, dynamic>> religiousOptions = [
    {'value': 'Christian', 'icon': Icons.church},
    {'value': 'Catholic', 'icon': Icons.church},
    {'value': 'Muslim', 'icon': Icons.mosque},
    {'value': 'Jewish', 'icon': Icons.star},
    {'value': 'Hindu', 'icon': Icons.temple_hindu},
    {'value': 'Buddhist', 'icon': Icons.self_improvement},
    {'value': 'Sikh', 'icon': Icons.temple_buddhist},
    {'value': 'Spiritual', 'icon': Icons.spa},
    {'value': 'Agnostic', 'icon': Icons.help_outline},
    {'value': 'Atheist', 'icon': Icons.not_interested},
    {'value': 'Other', 'icon': Icons.more_horiz},
    {'value': 'Prefer not to say', 'icon': Icons.lock_outline},
  ];

  static String formatReligiousList(List<String>? values) {
    if (values == null || values.isEmpty) return 'Add';
    return values.join(', ');
  }

  // ===================
  // SUBSTANCE USE
  // ===================
  static const List<String> drinkingOptions = [
    'Never', 'Rarely', 'Socially', 'Regularly', 'Prefer not to say',
  ];

  static const List<String> smokingOptions = [
    'Never', 'Occasionally', 'Regularly', 'Trying to quit', 'Prefer not to say',
  ];

  static const List<String> weedOptions = [
    'Never', 'Occasionally', 'Regularly', 'Prefer not to say',
  ];

  static String formatSubstanceUse(String? drinking, String? smoking, String? weed) {
    final parts = <String>[];
    if (drinking != null && drinking != 'Prefer not to say') {
      parts.add('Drinks: $drinking');
    }
    if (smoking != null && smoking != 'Prefer not to say') {
      parts.add('Smokes: $smoking');
    }
    if (weed != null && weed != 'Prefer not to say') {
      parts.add('Cannabis: $weed');
    }
    if (parts.isEmpty) return 'Add';
    return parts.join(' • ');
  }

  // ===================
  // CHILDREN OPTIONS
  // ===================
  static const List<Map<String, dynamic>> hasChildrenOptions = [
    {'value': 'no_children', 'label': "Don't have children", 'icon': Icons.person_outline},
    {'value': 'have_children', 'label': 'Have children', 'icon': Icons.family_restroom},
  ];

  static const List<Map<String, dynamic>> wantChildrenOptions = [
    {'value': 'want_children', 'label': 'Want children', 'icon': Icons.child_care},
    {'value': 'dont_want_children', 'label': "Don't want", 'icon': Icons.do_not_disturb},
    {'value': 'open_to_children', 'label': 'Open to it', 'icon': Icons.help_outline},
    {'value': 'not_sure', 'label': 'Not sure yet', 'icon': Icons.question_mark},
  ];

  static String getHasChildrenLabel(String? value) {
    if (value == null) return '';
    return hasChildrenOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  static String getWantChildrenLabel(String? value) {
    if (value == null) return '';
    return wantChildrenOptions.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    )['label'];
  }

  static String formatChildren(String? has, String? wants) {
    final h = getHasChildrenLabel(has);
    final w = getWantChildrenLabel(wants);
    if (h.isEmpty && w.isEmpty) return 'Add';
    if (h.isEmpty) return w;
    if (w.isEmpty) return h;
    return '$h • $w';
  }

  // ===================
  // CAMPUS OPTIONS
  // ===================
  static const List<String> campusOptions = [
    'Atlanta Campus',
    'Alpharetta Campus',
    'Clarkston Campus',
    'Decatur Campus',
    'Dunwoody Campus',
    'Newton Campus',
  ];

  static const List<String> religionOptions = [
    'Christian',
    'Catholic',
    'Muslim',
    'Jewish',
    'Hindu',
    'Buddhist',
    'Sikh',
    'Spiritual',
    'Agnostic',
    'Atheist',
    'Other',
    'Prefer not to say',
  ];

  // Ethnicity values for filter sheets - returns stored Firestore values
  static List<String> get ethnicityOptionsList => 
    ethnicityOptions.map((o) => o['value'] as String).toList();

  // Get display label for ethnicity filter value
  static String getEthnicityFilterLabel(String value) {
    final option = ethnicityOptions.where((o) => o['value'] == value);
    if (option.isNotEmpty) return option.first['label'] as String;
    return value;
  }

  // ===================
  // HEIGHT HELPERS
  // ===================
  static String formatHeight(int? heightCm) {
    if (heightCm == null || heightCm == 0) return 'Add';
    final totalInches = (heightCm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  // ===================
  // HOMETOWN HELPER
  // ===================
  static String formatHometown(String? city, String? state) {
    if (city == null && state == null) return 'Add';
    if (city != null && state != null) return '$city, $state';
    return city ?? state ?? 'Add';
  }

  // ===================
  // WORKPLACE HELPER
  // ===================
  static String formatWorkplace(String? workplace, String? jobTitle) {
    if (workplace == null && jobTitle == null) return 'Add';
    if (workplace != null && jobTitle != null) return '$jobTitle at $workplace';
    return jobTitle ?? workplace ?? 'Add';
  }
}
