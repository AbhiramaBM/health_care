class MealPhotoModel {
  final String id;
  final String patientId;
  final String photoUrl;
  final String? mealType; // Breakfast, Lunch, Dinner, Snack
  final String? description;
  final DateTime loggedAt;

  MealPhotoModel({
    required this.id,
    required this.patientId,
    required this.photoUrl,
    this.mealType,
    this.description,
    required this.loggedAt,
  });

  factory MealPhotoModel.fromJson(Map<String, dynamic> json) {
    return MealPhotoModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      photoUrl: (json['photoUrl'] ?? json['url'] ?? json['imageUrl'] ?? '').toString(),
      mealType: (json['mealType'] ?? json['type'] ?? 'Meal')?.toString(),
      description: (json['description'] ?? json['notes'])?.toString(),
      loggedAt: json['loggedAt'] != null
          ? DateTime.tryParse(json['loggedAt'].toString()) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'photoUrl': photoUrl,
      'mealType': mealType,
      'description': description,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }
}
