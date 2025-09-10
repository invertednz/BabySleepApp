class Baby {
  String id;
  String name;
  DateTime birthdate;
  String? gender;
  double? weightKg;
  double? heightCm;
  double? headCircumferenceCm;
  double? chestCircumferenceCm;
  List<String> completedMilestones;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Diaper preferences
  int? wetDiapersPerDay;
  int? dirtyDiapersPerDay;
  String? stoolColor;
  String? diaperNotes;
  
  // Sleep schedule
  String? bedtime;
  String? wakeTime;
  List<Map<String, String>>? naps;
  
  // Feeding preferences
  String? feedingMethod;
  int? feedingsPerDay;
  double? amountPerFeeding;
  int? feedingDuration;

  Baby({
    required this.id,
    required this.name,
    required this.birthdate,
    this.gender,
    this.weightKg,
    this.heightCm,
    this.headCircumferenceCm,
    this.chestCircumferenceCm,
    List<String>? completedMilestones,
    this.createdAt,
    this.updatedAt,
    this.wetDiapersPerDay,
    this.dirtyDiapersPerDay,
    this.stoolColor,
    this.diaperNotes,
    this.bedtime,
    this.wakeTime,
    this.naps,
    this.feedingMethod,
    this.feedingsPerDay,
    this.amountPerFeeding,
    this.feedingDuration,
  }) : completedMilestones = completedMilestones ?? [];
  
  // Factory constructor to create a Baby from JSON data
  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: json['id'],
      name: json['name'],
      birthdate: DateTime.parse(json['birthdate']),
      gender: json['gender'],
      weightKg: json['weight_kg']?.toDouble(),
      heightCm: json['height_cm']?.toDouble(),
      headCircumferenceCm: json['head_circumference_cm']?.toDouble(),
      chestCircumferenceCm: json['chest_circumference_cm']?.toDouble(),
      completedMilestones: json['completed_milestones'] != null
          ? List<String>.from(json['completed_milestones'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      wetDiapersPerDay: json['wet_diapers_per_day'],
      dirtyDiapersPerDay: json['dirty_diapers_per_day'],
      stoolColor: json['stool_color'],
      diaperNotes: json['diaper_notes'],
      bedtime: json['bedtime'],
      wakeTime: json['wake_time'],
      naps: json['naps'] != null
          ? List<Map<String, String>>.from(json['naps'])
          : null,
      feedingMethod: json['feeding_method'],
      feedingsPerDay: json['feedings_per_day'],
      amountPerFeeding: json['amount_per_feeding']?.toDouble(),
      feedingDuration: json['feeding_duration'],
    );
  }
  
  // Convert Baby object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthdate': birthdate.toIso8601String(),
      'gender': gender,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'head_circumference_cm': headCircumferenceCm,
      'chest_circumference_cm': chestCircumferenceCm,
      'completed_milestones': completedMilestones,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'wet_diapers_per_day': wetDiapersPerDay,
      'dirty_diapers_per_day': dirtyDiapersPerDay,
      'stool_color': stoolColor,
      'diaper_notes': diaperNotes,
      'bedtime': bedtime,
      'wake_time': wakeTime,
      'naps': naps,
      'feeding_method': feedingMethod,
      'feedings_per_day': feedingsPerDay,
      'amount_per_feeding': amountPerFeeding,
      'feeding_duration': feedingDuration,
    };
  }
  
  // Create a copy of this Baby with optional new values
  Baby copyWith({
    String? id,
    String? name,
    DateTime? birthdate,
    String? gender,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    double? chestCircumferenceCm,
    List<String>? completedMilestones,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wetDiapersPerDay,
    int? dirtyDiapersPerDay,
    String? stoolColor,
    String? diaperNotes,
    String? bedtime,
    String? wakeTime,
    List<Map<String, String>>? naps,
    String? feedingMethod,
    int? feedingsPerDay,
    double? amountPerFeeding,
    int? feedingDuration,
  }) {
    return Baby(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      chestCircumferenceCm: chestCircumferenceCm ?? this.chestCircumferenceCm,
      completedMilestones: completedMilestones ?? List.from(this.completedMilestones),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wetDiapersPerDay: wetDiapersPerDay ?? this.wetDiapersPerDay,
      dirtyDiapersPerDay: dirtyDiapersPerDay ?? this.dirtyDiapersPerDay,
      stoolColor: stoolColor ?? this.stoolColor,
      diaperNotes: diaperNotes ?? this.diaperNotes,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      naps: naps ?? this.naps,
      feedingMethod: feedingMethod ?? this.feedingMethod,
      feedingsPerDay: feedingsPerDay ?? this.feedingsPerDay,
      amountPerFeeding: amountPerFeeding ?? this.amountPerFeeding,
      feedingDuration: feedingDuration ?? this.feedingDuration,
    );
  }
}
