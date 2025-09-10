class Concern {
  final String id;
  final String text;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Concern({
    required this.id,
    required this.text,
    required this.isResolved,
    required this.createdAt,
    this.resolvedAt,
  });

  // Create a Concern from JSON data
  factory Concern.fromJson(Map<String, dynamic> json) {
    return Concern(
      id: json['id'],
      text: json['text'],
      isResolved: json['is_resolved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  // Convert Concern object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_resolved': isResolved,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  Concern copyWith({
    String? id,
    String? text,
    bool? isResolved,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Concern(
      id: id ?? this.id,
      text: text ?? this.text,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
