import 'package:flutter/material.dart';

/// Represents a user's answer to a prompt
class Prompt {
  final String id;
  final String category;
  final String question;  // The prompt question itself
  final String text;      // User's text answer

  Prompt({
    required this.id,
    required this.category,
    required this.question,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'text': text,
    };
  }

  factory Prompt.fromMap(Map<String, dynamic> map) {
    return Prompt(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      question: map['question'] ?? map['id']?.split('-').last ?? '',
      text: map['text'] ?? '',
    );
  }
}

/// Voice prompt - a single voice recording prompt
class VoicePrompt {
  final String question;
  final String? audioUrl;
  final String? localPath;
  final int durationSeconds;

  VoicePrompt({
    required this.question,
    this.audioUrl,
    this.localPath,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
    };
  }

  factory VoicePrompt.fromMap(Map<String, dynamic> map) {
    return VoicePrompt(
      question: map['question'] ?? '',
      audioUrl: map['audioUrl'],
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
}

/// Prompt categories with icons and colors
class PromptCategory {
  final String name;
  final IconData icon;
  final String description;

  const PromptCategory({
    required this.name,
    required this.icon,
    required this.description,
  });

  static const starters = PromptCategory(
    name: 'Conversation Starters',
    icon: Icons.chat_bubble_outline,
    description: 'Great ways to break the ice',
  );

  static const personality = PromptCategory(
    name: 'Personality',
    icon: Icons.star_outline,
    description: 'Show off who you are',
  );

  static const dateVibes = PromptCategory(
    name: 'Date Vibes',
    icon: Icons.favorite_outline,
    description: 'Your ideal romance',
  );

  static const funQuirks = PromptCategory(
    name: 'Fun & Quirks',
    icon: Icons.mood,
    description: 'The fun stuff',
  );

  static const deepThoughts = PromptCategory(
    name: 'Deep Thoughts',
    icon: Icons.lightbulb_outline,
    description: 'Get philosophical',
  );

  static List<PromptCategory> get all => [
    starters,
    personality,
    dateVibes,
    funQuirks,
    deepThoughts,
  ];
}

/// Open-ended "complete the sentence" style prompts
class PromptTemplates {
  static final Map<String, List<String>> prompts = {
    'Conversation Starters': [
      "A random fact I know is...",
      "The way to my heart is...",
      "You should message me if...",
      "Two truths and a lie about me...",
      "The best gift I ever received was...",
      "My go-to karaoke song is...",
      "A skill I'm secretly proud of is...",
      "The last thing that made me laugh out loud was...",
    ],
    'Personality': [
      "I'm convinced I'm the only person who...",
      "My friends would describe me as...",
      "I get way too excited about...",
      "The most spontaneous thing I've done is...",
      "My comfort movie is...",
      "I can't stop talking about...",
      "My biggest pet peeve is...",
      "Something I'll never apologize for is...",
    ],
    'Date Vibes': [
      "My ideal first date is...",
      "A perfect Sunday with me looks like...",
      "The quickest way to win me over is...",
      "My love language is...",
      "I know we'll vibe if you...",
      "My dream vacation is...",
      "The best date I've been on was...",
      "Together, we could...",
    ],
    'Fun & Quirks': [
      "My most controversial opinion is...",
      "I'm weirdly attracted to...",
      "My guilty pleasure is...",
      "The hill I will die on is...",
      "My hidden talent is...",
      "I'm irrationally afraid of...",
      "My comfort food is...",
      "The emoji that best describes me is...",
    ],
    'Deep Thoughts': [
      "Something I'm still trying to figure out is...",
      "The best advice I ever got was...",
      "I feel most alive when...",
      "In 5 years, I hope to...",
      "Something that changed my perspective was...",
      "What I value most in a relationship is...",
      "The thing I'm most grateful for is...",
      "A life goal of mine is...",
    ],
  };

  /// Voice prompt questions (user picks one)
  static const List<String> voicePrompts = [
    "Tell me about your perfect day...",
    "What's your hot take?",
    "Do your best impression...",
    "Describe yourself in 3 words...",
    "What gets you excited?",
    "Tell me a fun fact about you...",
    "What are you looking for?",
    "Say something in another language...",
  ];
}
