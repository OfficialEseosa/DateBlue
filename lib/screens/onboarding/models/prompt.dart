class Prompt {
  final String id;
  final String category;
  final String text;

  Prompt({
    required this.id,
    required this.category,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'text': text,
    };
  }

  factory Prompt.fromMap(Map<String, dynamic> map) {
    return Prompt(
      id: map['id'],
      category: map['category'],
      text: map['text'],
    );
  }
}

class PromptCategory {
  static const String aboutMe = 'About Me';
  static const String letsChatAbout = "Let's Chat About";
  static const String myIdealDate = 'My Ideal Date';
  static const String funFacts = 'Fun Facts';
  static const String wouldYouRather = 'Would You Rather';
  static const String thisOrThat = 'This or That';

  static List<String> get all => [
        aboutMe,
        letsChatAbout,
        myIdealDate,
        funFacts,
        wouldYouRather,
        thisOrThat,
      ];
}

class PromptTemplates {
  static final Map<String, List<String>> prompts = {
    PromptCategory.aboutMe: [
      'My simple pleasures',
      'I geek out on',
      'A life goal of mine',
      'I\'m weirdly attracted to',
      'Most spontaneous thing I\'ve done',
      'Change my mind about',
      'Don\'t hate me if I',
      'Green flags I look for',
    ],
    PromptCategory.letsChatAbout: [
      'The key to my heart is',
      'We\'ll get along if',
      'I want someone who',
      'Together we could',
      'I\'m looking for',
      'The way to win me over',
      'Dating me is like',
      'My love language is',
    ],
    PromptCategory.myIdealDate: [
      'Perfect first date',
      'Best date I\'ve been on',
      'My date night outfit',
      'Ideal Sunday morning',
      'Weekend plans',
      'Dream vacation spot',
      'Favorite date activity',
      'Must-try restaurant',
    ],
    PromptCategory.funFacts: [
      'Unusual skill I have',
      'Random fact I love',
      'Best advice I\'ve received',
      'Proudest accomplishment',
      'Hidden talent',
      'I won\'t shut up about',
      'My guilty pleasure',
      'Superpower I\'d choose',
    ],
    PromptCategory.wouldYouRather: [
      'Beach vacation or mountain retreat?',
      'Coffee or tea?',
      'Early bird or night owl?',
      'Cook at home or eat out?',
      'Summer or winter?',
      'Texting or calling?',
      'Movies or concerts?',
      'Dogs or cats?',
    ],
    PromptCategory.thisOrThat: [
      'Netflix or going out?',
      'Staying in or exploring?',
      'Sweet or savory?',
      'Spontaneous or planned?',
      'City or countryside?',
      'Books or podcasts?',
      'Working out or chilling?',
      'Adventure or relaxation?',
    ],
  };
}
