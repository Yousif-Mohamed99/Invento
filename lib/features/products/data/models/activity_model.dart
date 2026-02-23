enum ActivityType { newOrder, lowStock }

class ActivityModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;
  final String referenceId;

  ActivityModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    required this.referenceId,
  });
}
