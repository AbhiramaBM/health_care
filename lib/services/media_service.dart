import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/meal_photo_model.dart';

class MediaService {
  final ApiClient _client = ApiClient();

  /// Get meal photos for a patient from their daily logs: GET /logs/daily/:patientId
  Future<List<MealPhotoModel>> getPatientMealPhotos(String patientId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.logsDaily(patientId),
        queryParameters: {'page': 1, 'limit': 30},
      );

      final dynamic data = response.data;
      List logsList;
      if (data is List) {
        logsList = data;
      } else if (data is Map && data['logs'] is List) {
        logsList = data['logs'];
      } else if (data is Map && data['dailyLogs'] is List) {
        logsList = data['dailyLogs'];
      } else if (data is Map && data['data'] is List) {
        logsList = data['data'];
      } else {
        logsList = [];
      }

      final photos = <MealPhotoModel>[];
      for (final logItem in logsList) {
        if (logItem is! Map) continue;
        final log = Map<String, dynamic>.from(logItem);
        final logId = log['id']?.toString() ?? '';
        final date = log['date'] != null
            ? DateTime.tryParse(log['date'].toString()) ?? DateTime.now()
            : DateTime.now();

        void addIfPresent(String key, String mealType) {
          final url = log[key]?.toString();
          if (url != null && url.isNotEmpty) {
            photos.add(
              MealPhotoModel(
                id: '${logId}_$mealType',
                patientId: patientId,
                photoUrl: url,
                mealType: mealType,
                description: log['notes']?.toString(),
                loggedAt: date,
              ),
            );
          }
        }

        addIfPresent('breakfastPhoto', 'Breakfast');
        addIfPresent('lunchPhoto', 'Lunch');
        addIfPresent('dinnerPhoto', 'Dinner');
        addIfPresent('snackPhoto', 'Snack');
        addIfPresent('juicePhoto', 'Juice');
      }

      return photos;
    } catch (_) {
      return [];
    }
  }
}
