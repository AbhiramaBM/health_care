import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/socket/socket_service.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/error_utils.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../services/prescription_service.dart';

class AlertProvider with ChangeNotifier {
  final AlertService _alertService = AlertService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final TokenStorage _tokenStorage = TokenStorage();

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAcknowledged = false;
  String? _selectedPriority;
  String? _selectedPatientId;

  List<AlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showAcknowledged => _showAcknowledged;
  String? get selectedPriority => _selectedPriority;
  String? get selectedStatus => _showAcknowledged ? 'acknowledged' : 'pending';

  final _alertNotificationController = StreamController<AlertModel>.broadcast();
  Stream<AlertModel> get onAlertNotification => _alertNotificationController.stream;
  final Set<String> _notifiedAlertIds = <String>{};
  StreamSubscription? _socketAlertSub;

  AlertProvider() {
    _socketAlertSub = SocketService().onAlertReceived.listen((data) {
      try {
        final alert = AlertModel.fromJson(data);
        final existingIdx = _alerts.indexWhere((a) => a.id == alert.id);
        if (existingIdx != -1) {
          _alerts[existingIdx] = alert;
        } else {
          _alerts.insert(0, alert);
        }
        if (!alert.isAcknowledged && !_notifiedAlertIds.contains(alert.id)) {
          _notifiedAlertIds.add(alert.id);
          _alertNotificationController.add(alert);
        }
        notifyListeners();
      } catch (_) {}
    });
  }

  int get pendingAlertsCount =>
      _alerts.where((a) => !a.isAcknowledged).length;

  Future<List<AlertModel>> _getLocallyUnacknowledgedAlerts() async {
    try {
      final rawList = await _tokenStorage.getUnacknowledgedAlertsRaw();
      final List<AlertModel> list = [];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw);
          if (map is Map<String, dynamic>) {
            list.add(AlertModel.fromJson(map));
          }
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> fetchAlerts({bool refresh = false}) async {
    if (_alerts.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _alertService.getAlerts(
        acknowledged: _showAcknowledged,
        priority: _selectedPriority,
        patientId: _selectedPatientId,
      );

      final unackedAlerts = await _getLocallyUnacknowledgedAlerts();
      final unackedIds = unackedAlerts.map((a) => a.id).toSet();

      if (_showAcknowledged) {
        // Exclude alerts that were unacknowledged by the doctor
        _alerts = fetched.where((a) => !unackedIds.contains(a.id)).toList();
      } else {
        // Filter local unacknowledged alerts by priority & patient if specified
        final localPending = unackedAlerts.where((a) {
          if (_selectedPriority != null &&
              _selectedPriority!.isNotEmpty &&
              a.severity.toUpperCase() != _selectedPriority!.toUpperCase()) {
            return false;
          }
          if (_selectedPatientId != null &&
              _selectedPatientId!.isNotEmpty &&
              a.patientId != _selectedPatientId) {
            return false;
          }
          return true;
        }).toList();

        // Merge local unacknowledged alerts ahead of fetched pending alerts
        final fetchedIds = fetched.map((a) => a.id).toSet();
        final filteredLocal =
            localPending.where((a) => !fetchedIds.contains(a.id)).toList();

        _alerts = [...filteredLocal, ...fetched];

        // Notify for any pending alerts that haven't been shown yet
        for (final a in _alerts) {
          if (!a.isAcknowledged && !_notifiedAlertIds.contains(a.id)) {
            _notifiedAlertIds.add(a.id);
            _alertNotificationController.add(a);
          }
        }
      }
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filter({bool? acknowledged, String? priority, String? patientId}) {
    if (acknowledged != null) _showAcknowledged = acknowledged;
    if (priority != null) _selectedPriority = priority.isEmpty ? null : priority;
    if (patientId != null) _selectedPatientId = patientId.isEmpty ? null : patientId;
    fetchAlerts(refresh: true);
  }

  Future<bool> acknowledge(String alertId, {String? noteContent}) async {
    _errorMessage = null;
    try {
      final updated = await _alertService.acknowledgeAlert(alertId, noteContent: noteContent);
      await _tokenStorage.removeUnacknowledgedAlertId(alertId);
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> unacknowledge(String alertId) async {
    _errorMessage = null;
    try {
      // 1. Attempt backend unacknowledge in case server has or adds support
      try {
        await _alertService.unacknowledgeAlert(alertId);
      } catch (_) {
        // Live server currently returns 404 Route Not Found; handled gracefully
      }

      // 2. Find target alert model in current list or fetch by ID
      AlertModel? target = _alerts.where((a) => a.id == alertId).firstOrNull;
      if (target == null) {
        try {
          target = await _alertService.getAlertById(alertId);
        } catch (_) {}
      }

      if (target != null) {
        final updated = target.copyWith(
          status: 'pending',
          isAcknowledged: false,
        );

        // 3. Persist locally to SharedPreferences
        await _tokenStorage.saveUnacknowledgedAlertRaw(
          alertId,
          jsonEncode(updated.toJson()),
        );

        // 4. Update in-memory list
        if (_showAcknowledged) {
          _alerts.removeWhere((a) => a.id == alertId);
        } else {
          final index = _alerts.indexWhere((a) => a.id == alertId);
          if (index != -1) {
            _alerts[index] = updated;
          } else {
            _alerts.insert(0, updated);
          }
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> ignore(String alertId, {String? noteContent}) async {
    _errorMessage = null;
    try {
      final updated = await _alertService.ignoreAlert(alertId, noteContent: noteContent);
      await _tokenStorage.removeUnacknowledgedAlertId(alertId);
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> messagePatient(String alertId, {required String messageText}) async {
    _errorMessage = null;
    try {
      final updated = await _alertService.messagePatientAlert(alertId, messageText: messageText);
      await _tokenStorage.removeUnacknowledgedAlertId(alertId);
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeMedication({
    required String alertId,
    String? patientId,
    required String noteContent,
    required List<Map<String, dynamic>> medications,
  }) async {
    _errorMessage = null;
    try {
      try {
        final updated = await _alertService.changeMedicationAlert(
          alertId,
          noteContent: noteContent,
          medications: medications,
        );
        await _tokenStorage.removeUnacknowledgedAlertId(alertId);
        _updateLocalAlert(updated);
        return true;
      } on ApiException catch (e) {
        // If the backend requires a DRAFT prescription because current prescription is SENT:
        final isSentPrescriptionConflict = e.statusCode == 409 &&
            (e.message.toLowerCase().contains('sent prescription') ||
             e.message.toLowerCase().contains('draft prescription'));

        if (isSentPrescriptionConflict) {
          // Resolve patient ID from argument or cached alerts
          final resolvedPatientId = patientId ??
              _alerts.where((a) => a.id == alertId).firstOrNull?.patientId;

          if (resolvedPatientId != null && resolvedPatientId.isNotEmpty) {
            // Auto-create a DRAFT prescription with the new medications
            await _prescriptionService.createPrescription(
              patientId: resolvedPatientId,
              medications: medications,
              internalNotes: noteContent,
            );

            // Retry applying medication change to alert
            final updated = await _alertService.changeMedicationAlert(
              alertId,
              noteContent: noteContent,
              medications: medications,
            );
            await _tokenStorage.removeUnacknowledgedAlertId(alertId);
            _updateLocalAlert(updated);
            return true;
          }
        }
        rethrow;
      }
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  void _updateLocalAlert(AlertModel updated) {
    final index = _alerts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      if (!_showAcknowledged && updated.isAcknowledged) {
        _alerts.removeAt(index);
      } else {
        _alerts[index] = updated;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socketAlertSub?.cancel();
    _alertNotificationController.close();
    super.dispose();
  }
}
