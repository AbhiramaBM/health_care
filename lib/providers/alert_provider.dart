import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';

class AlertProvider with ChangeNotifier {
  final AlertService _alertService = AlertService();

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

  int get pendingAlertsCount =>
      _alerts.where((a) => !a.isAcknowledged).length;

  Future<void> fetchAlerts({bool refresh = false}) async {
    if (_alerts.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _alerts = await _alertService.getAlerts(
        acknowledged: _showAcknowledged,
        priority: _selectedPriority,
        patientId: _selectedPatientId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
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
    try {
      final updated = await _alertService.acknowledgeAlert(alertId, noteContent: noteContent);
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> ignore(String alertId, {String? noteContent}) async {
    try {
      final updated = await _alertService.ignoreAlert(alertId, noteContent: noteContent);
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> messagePatient(String alertId, {required String messageText}) async {
    try {
      final updated = await _alertService.messagePatientAlert(alertId, messageText: messageText);
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeMedication({
    required String alertId,
    required String noteContent,
    required List<Map<String, dynamic>> medications,
  }) async {
    try {
      final updated = await _alertService.changeMedicationAlert(
        alertId,
        noteContent: noteContent,
        medications: medications,
      );
      _updateLocalAlert(updated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
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
}
