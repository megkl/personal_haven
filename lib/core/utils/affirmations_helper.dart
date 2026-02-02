import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AffirmationsHelper {
  static const String _keyLastDate = 'affirmation_last_date';
  static const String _keyCurrentAffirmation = 'affirmation_current';

  static const List<String> affirmations = [
    "You are capable of amazing things ",
    "Today is full of possibilities",
    "You deserve peace and happiness",
    "Your feelings are valid",
    "You are stronger than you think",
    "Every day is a fresh start",
    "You are worthy of love and kindness",
    "Your journey is unique and beautiful",
    "You have the power to create change",
    "It's okay to take things one step at a time",
    "You are enough, just as you are",
    "Your presence makes a difference",
    "You are resilient and brave",
    "Believe in your inner strength",
    "You are growing every single day",
    "Your dreams are worth pursuing",
    "You bring light to others",
    "Trust the timing of your life",
    "You are deserving of all good things",
    "Your voice matters",
    "You are making progress, even when it doesn't feel like it",
    "Be gentle with yourself today",
    "You are loved more than you know",
    "Your potential is limitless",
    "Today, choose joy",
    "You are not alone in this journey",
    "Every breath is a gift",
    "You have overcome challenges before, and you will again",
    "Your kindness creates ripples of positivity",
    "You are exactly where you need to be",
    "Embrace your imperfections—they make you unique",
    "You have so much to offer the world",
    "Take pride in how far you've come",
    "You are a work in progress, and that's beautiful",
    "Your heart knows the way—trust it",
  ];

  /// Get today's affirmation (same one for the whole day)
  static Future<String> getTodayAffirmation() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString(DateTime.now());
    final lastDate = prefs.getString(_keyLastDate);

    // If it's a new day, pick a new affirmation
    if (lastDate != today) {
      final random = Random();
      final index = random.nextInt(affirmations.length);
      final newAffirmation = affirmations[index];

      await prefs.setString(_keyLastDate, today);
      await prefs.setString(_keyCurrentAffirmation, newAffirmation);

      return newAffirmation;
    }

    // Return the stored affirmation for today
    return prefs.getString(_keyCurrentAffirmation) ?? affirmations[0];
  }

  /// Get a random affirmation (different each time)
  static String getRandomAffirmation() {
    final random = Random();
    return affirmations[random.nextInt(affirmations.length)];
  }

  /// Get affirmation by index
  static String getAffirmation(int index) {
    return affirmations[index % affirmations.length];
  }

  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}