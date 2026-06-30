import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AffirmationsHelper {
  static const String _keyLastDate = 'affirmation_last_date';
  static const String _keyCurrentAffirmation = 'affirmation_current';

  static const List<String> affirmations = [
    "You are capable of amazing things",
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
    "You can begin again without starting over",
    "Small steps still move you forward",
    "You are allowed to rest without guilt",
    "Your pace is valid",
    "You can hold hope and uncertainty at the same time",
    "You are learning to trust yourself",
    "Today, your best is enough",
    "You do not have to solve everything at once",
    "Your softness is not weakness",
    "You are becoming more yourself every day",
    "You are allowed to ask for support",
    "A calm breath can be a fresh beginning",
    "You are safe to take up space",
    "Your needs matter",
    "You can choose one kind thing for yourself today",
    "Progress can be quiet and still be real",
    "You are worthy before you achieve anything",
    "You can move through this moment gently",
    "Your future is still open",
    "You are not behind; you are on your path",
    "You can make room for joy today",
    "Your courage counts, even when it feels small",
    "You are allowed to celebrate tiny wins",
    "You can release what is not yours to carry",
    "There is wisdom in slowing down",
    "You are building a life that can hold you",
    "Your effort matters",
    "You can be proud of showing up",
    "Peace can start with one honest breath",
    "You are more than your hardest day",
    "You are allowed to change your mind",
    "You have permission to take the next gentle step",
    "Your story is still unfolding",
    "You can meet yourself with compassion today",
    "You are growing in ways you may not see yet",
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
