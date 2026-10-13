import 'package:flutter/material.dart';
import '../core/utils/error_utils.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityService _communityService = CommunityService();

  List<CommunityModel> _communities = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  String? _successMessage;

  List<CommunityModel> get communities => _communities;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Fetch all available communities from backend
  Future<void> fetchCommunities({bool refresh = false}) async {
    if (_communities.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _communities = await _communityService.getCommunities();
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new community and persist to database via API
  Future<bool> createCommunity({
    required String name,
    String? description,
    String? imageUrl,
    int durationWeeks = 12,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final newCommunity = await _communityService.createCommunity(
        name: name,
        description: description,
        imageUrl: imageUrl,
        durationWeeks: durationWeeks,
      );

      // Immediately insert into list for responsive UX
      final existingIndex = _communities.indexWhere((c) => c.id == newCommunity.id);
      if (existingIndex != -1) {
        _communities[existingIndex] = newCommunity;
      } else {
        _communities.insert(0, newCommunity);
      }

      _successMessage = 'Community created successfully.';
      notifyListeners();

      // Refresh from server to sync all fields & room mappings
      _refreshInBackground();

      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final updated = await _communityService.getCommunities();
      _communities = updated;
      notifyListeners();
    } catch (_) {}
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
