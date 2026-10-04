class DailyQuest {
  final String title;
  final String description;
  final int xpReward;
  final bool isCompleted;

  const DailyQuest({
    required this.title,
    required this.description,
    required this.xpReward,
    this.isCompleted = false,
  });

  DailyQuest copyWith({
    String? title,
    String? description,
    int? xpReward,
    bool? isCompleted,
  }) {
    return DailyQuest(
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}