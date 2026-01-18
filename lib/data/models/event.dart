class Event {
  final String id;
  final String title;
  final DateTime time;
  final String? description;

  Event({
    required this.id,
    required this.title,
    required this.time,
    this.description,
  });
}