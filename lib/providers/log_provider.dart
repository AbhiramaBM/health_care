import 'package:flutter/material.dart';
import '../core/utils/error_utils.dart';
import '../models/daily_log_model.dart';
import '../models/clinical_note_model.dart';
import '../services/daily_log_service.dart';
import '../services/clinical_note_service.dart';

class LogProvider with ChangeNotifier {
  final DailyLogService _logService = DailyLogService();
  final ClinicalNoteService _noteService = ClinicalNoteService();

  List<DailyLogModel> _dailyLogs = [];
  List<ClinicalNoteModel> _patientNotes = [];
  List<ClinicalNoteModel> _logNotes = [];
  List<ClinicalNoteModel> _alertNotes = [];

  bool _isLoadingLogs = false;
  bool _isLoadingNotes = false;
  String? _errorMessage;

  List<DailyLogModel> get dailyLogs => _dailyLogs;
  List<ClinicalNoteModel> get patientNotes => _patientNotes;
  List<ClinicalNoteModel> get logNotes => _logNotes;
  List<ClinicalNoteModel> get alertNotes => _alertNotes;

  bool get isLoadingLogs => _isLoadingLogs;
  bool get isLoadingNotes => _isLoadingNotes;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDailyLogs(String patientId) async {
    _isLoadingLogs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dailyLogs = await _logService.getDailyLogs(patientId);
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  Future<void> fetchPatientNotes(String patientId) async {
    _isLoadingNotes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _patientNotes = await _noteService.getPatientNotes(patientId);
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  Future<bool> addPatientNote({
    required String patientId,
    required String content,
    String? category,
  }) async {
    try {
      final note = await _noteService.addPatientNote(
        patientId: patientId,
        content: content,
        category: category,
      );
      _patientNotes.insert(0, note);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchLogNotes(String logId) async {
    try {
      _logNotes = await _noteService.getLogNotes(logId);
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    }
  }

  Future<bool> addLogNote({
    required String logId,
    required String patientId,
    required String content,
  }) async {
    try {
      final note = await _noteService.addLogNote(
        logId: logId,
        patientId: patientId,
        content: content,
      );
      _logNotes.insert(0, note);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAlertNotes(String alertId) async {
    try {
      _alertNotes = await _noteService.getAlertNotes(alertId);
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
    }
  }

  Future<bool> addAlertNote({
    required String alertId,
    required String patientId,
    required String content,
  }) async {
    try {
      final note = await _noteService.addAlertNote(
        alertId: alertId,
        patientId: patientId,
        content: content,
      );
      _alertNotes.insert(0, note);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorUtils.toUserFriendlyMessage(e);
      notifyListeners();
      return false;
    }
  }
}
