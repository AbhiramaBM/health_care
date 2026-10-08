import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/prescription_model.dart';
import '../models/meal_photo_model.dart';
import '../services/patient_service.dart';
import '../services/prescription_service.dart';
import '../services/media_service.dart';

class PatientProvider with ChangeNotifier {
  final PatientService _patientService = PatientService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final MediaService _mediaService = MediaService();

  List<PatientModel> _patients = [];
  List<dynamic> _batches = [];
  PatientModel? _selectedPatient;
  List<PrescriptionModel> _prescriptions = [];
  List<MedicationModel> _medications = [];
  List<MealPhotoModel> _mealPhotos = [];

  bool _isLoading = false;
  bool _isDetailsLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedBatch;

  List<PatientModel> get patients => _patients;
  List<dynamic> get batches => _batches;
  PatientModel? get selectedPatient => _selectedPatient;
  List<PrescriptionModel> get prescriptions => _prescriptions;
  List<MedicationModel> get medications => _medications;
  List<MealPhotoModel> get mealPhotos => _mealPhotos;

  bool get isLoading => _isLoading;
  bool get isDetailsLoading => _isDetailsLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedBatch => _selectedBatch;

  Future<void> fetchPatients({bool refresh = false}) async {
    if (_patients.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _patients = await _patientService.getPatients(batch: _selectedBatch);
      _batches = await _patientService.getPatientBatches();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      return fetchPatients(refresh: true);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _patients = await _patientService.searchPatients(query.trim());
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByBatch(String? batch) {
    _selectedBatch = batch;
    fetchPatients(refresh: true);
  }

  Future<void> selectPatient(String patientId) async {
    _isDetailsLoading = true;
    notifyListeners();

    try {
      _selectedPatient = await _patientService.getPatientById(patientId);
      // Fetch associated prescriptions, medications, and meal photos
      _prescriptions = await _prescriptionService.getPrescriptions(patientId);
      _medications = await _prescriptionService.getMedications(patientId);
      _mealPhotos = await _mediaService.getPatientMealPhotos(patientId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPrescription({
    required String patientId,
    required List<Map<String, dynamic>> medications,
    String? advice,
    String? internalNotes,
  }) async {
    try {
      final newRx = await _prescriptionService.createPrescription(
        patientId: patientId,
        medications: medications,
        advice: advice,
        internalNotes: internalNotes,
      );
      _prescriptions.insert(0, newRx);
      // Also refresh active medications
      try {
        _medications = await _prescriptionService.getMedications(patientId);
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearSelection() {
    _selectedPatient = null;
    _prescriptions = [];
    _medications = [];
    _mealPhotos = [];
    notifyListeners();
  }
}
