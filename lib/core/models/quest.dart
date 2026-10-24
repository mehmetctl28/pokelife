class Quest {
  final String id;
  final String title;
  final int target;
  int current;
  final int rewardXp;
  bool isClaimed;

  Quest({
    required this.id,
    required this.title,
    required this.target,
    int? current,
    int? progress,
    required this.rewardXp,
    this.isClaimed = false,
  }) : current = current ?? progress ?? 0;

  // Farklı ekranlarda progress veya current kullanılmasına karşı tam uyumluluk:
  int get progress => current;
  set progress(int value) => current = value;

  // Hem isCompleted hem isComplete çağrılarını destekler:
  bool get isCompleted => current >= target;
  bool get isComplete => current >= target;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'current': current,
      'progress': current,
      'rewardXp': rewardXp,
      'isClaimed': isClaimed,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      target: map['target'] as int? ?? 1,
      current: (map['current'] ?? map['progress']) as int? ?? 0,
      rewardXp: map['rewardXp'] as int? ?? 25,
      isClaimed: map['isClaimed'] as bool? ?? false,
    );
  }
}