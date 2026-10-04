class Quest {
  final String id;
  final String title;
  final int target;
  final int rewardXp;
  final String type; // 'step' veya 'catch'
  int progress;
  bool isClaimed;

  Quest({
    required this.id,
    required this.title,
    required this.target,
    required this.rewardXp,
    required this.type,
    this.progress = 0,
    this.isClaimed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'rewardXp': rewardXp,
      'type': type,
      'progress': progress,
      'isClaimed': isClaimed,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'],
      title: map['title'],
      target: map['target'],
      rewardXp: map['rewardXp'],
      type: map['type'],
      progress: map['progress'] ?? 0,
      isClaimed: map['isClaimed'] ?? false,
    );
  }
}