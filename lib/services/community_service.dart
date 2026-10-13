import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/community_model.dart';

class CommunityService {
  final ApiClient _client = ApiClient();

  /// Default clinic location ID verified from backend
  static const String defaultClinicLocationId = '1abba7df-6cb9-47d3-b984-20e3211d7f6c';

  /// Get list of all available communities: GET /community/rooms & GET /batches
  Future<List<CommunityModel>> getCommunities() async {
    // 1. Fetch community rooms: GET /community/rooms
    final roomResponse = await _client.get(ApiEndpoints.communityRooms);
    final dynamic roomData = roomResponse.data;

    List roomsList = [];
    if (roomData is List) {
      roomsList = roomData;
    } else if (roomData is Map && roomData['rooms'] is List) {
      roomsList = roomData['rooms'];
    }

    // 2. Fetch batches to get descriptions/notes and details: GET /batches
    Map<String, Map<String, dynamic>> batchMap = {};
    try {
      final batchResponse = await _client.get(
        ApiEndpoints.batches,
        queryParameters: {'page': 1, 'limit': 100},
      );
      final dynamic batchData = batchResponse.data;
      List batchesList = [];
      if (batchData is List) {
        batchesList = batchData;
      } else if (batchData is Map && batchData['batches'] is List) {
        batchesList = batchData['batches'];
      }

      for (final b in batchesList) {
        if (b is Map) {
          final bMap = Map<String, dynamic>.from(b);
          final id = bMap['id']?.toString();
          final code = bMap['batchCode']?.toString();
          if (id != null) batchMap[id] = bMap;
          if (code != null) batchMap[code] = bMap;
        }
      }
    } catch (_) {
      // Continue even if batches lookup fails
    }

    // 3. Map into CommunityModel objects
    final communities = <CommunityModel>[];
    for (final r in roomsList) {
      if (r is! Map) continue;
      final rMap = Map<String, dynamic>.from(r);
      final batchId = rMap['batchId']?.toString();
      final batchInfo = batchId != null ? batchMap[batchId] : null;

      final merged = Map<String, dynamic>.from(rMap);
      if (batchInfo != null) {
        if (merged['description'] == null && batchInfo['notes'] != null) {
          merged['description'] = batchInfo['notes'];
        }
        if (merged['batchCode'] == null && batchInfo['batchCode'] != null) {
          merged['batchCode'] = batchInfo['batchCode'];
        }
        if (merged['createdBy'] == null && batchInfo['createdBy'] != null) {
          merged['createdBy'] = batchInfo['createdBy'];
        }
      }

      communities.add(CommunityModel.fromJson(merged));
    }

    // Sort newest first
    communities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return communities;
  }

  /// Create a new community: POST /batches (creates persistent database record and community room)
  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? imageUrl,
    int durationWeeks = 12,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client.post(
      ApiEndpoints.batches,
      data: {
        'clinicLocationId': defaultClinicLocationId,
        'startDate': today,
        'durationWeeks': durationWeeks,
        'notes': (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : name.trim(),
        'name': name.trim(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
      },
    );

    final dynamic data = response.data;
    final Map<String, dynamic> batchData = (data is Map && data['batch'] is Map)
        ? Map<String, dynamic>.from(data['batch'])
        : (data is Map ? Map<String, dynamic>.from(data) : {});

    // Augment with name and imageUrl if returned without custom name
    if (batchData['name'] == null || batchData['name'].toString().isEmpty) {
      batchData['name'] = name.trim();
    }
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      batchData['imageUrl'] = imageUrl.trim();
    }
    if (description != null && description.trim().isNotEmpty) {
      batchData['description'] = description.trim();
    }

    return CommunityModel.fromJson(batchData);
  }
}
