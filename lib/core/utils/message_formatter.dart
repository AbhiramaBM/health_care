/// Centralized message and alert formatting system for the Healthcare platform.
/// Translates internal technical codes, enums, database identifiers, and truncated
/// text into clean, human-readable, sentence-case clinical language.
class MessageFormatter {
  MessageFormatter._();

  // Universally recognized abbreviations that should maintain exact casing
  static final Set<String> _preservedAcronyms = {
    'hba1c', 'bp', 'bmi', 'otp', 'pin', 'fbs', 'ppbs', 'dm', 'id', 'fcm',
    'whatsapp', 'covid', 'ecg', 'spo2', 'hr', 'ahc', 'am', 'pm'
  };

  /// Converts a technical string, screaming snake_case, or title into clean Sentence case.
  /// Example: 'NO_LOG_3_DAYS' -> 'Patient has not logged in'
  /// Example: 'ACTIVE_ALERTS' -> 'Active alerts'
  static String toSentenceCase(String input) {
    var text = input.trim();
    if (text.isEmpty) return '';

    // Check direct technical replacements first
    final direct = _directTextReplacements[text.toUpperCase()];
    if (direct != null) return direct;

    // Replace underscores and hyphens with spaces
    text = text.replaceAll('_', ' ').replaceAll('-', ' ').trim();

    // Split words and process casing
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final lowerWord = word.toLowerCase();

      if (_preservedAcronyms.contains(lowerWord)) {
        // Format acronym appropriately
        if (lowerWord == 'hba1c') {
          buffer.write('HbA1c');
        } else if (lowerWord == 'whatsapp') {
          buffer.write('WhatsApp');
        } else {
          buffer.write(lowerWord.toUpperCase());
        }
      } else if (i == 0) {
        // First word capitalized
        buffer.write(word[0].toUpperCase());
        if (word.length > 1) {
          buffer.write(word.substring(1).toLowerCase());
        }
      } else {
        // Subsequent words lowercased
        buffer.write(word.toLowerCase());
      }

      if (i < words.length - 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  /// Maps alert types / technical identifiers to clear, sentence-case titles.
  static String formatAlertTitle(String? rawType, [String? fallbackTitle]) {
    final candidate = (rawType != null && rawType.trim().isNotEmpty)
        ? rawType.trim()
        : (fallbackTitle?.trim() ?? 'Clinical alert');

    final upper = candidate.toUpperCase();

    // 1. Dynamic check for NO_LOG variants
    if (upper.startsWith('NO_LOG')) {
      return 'Patient has not logged in';
    }

    // 2. Known Alert Type titles
    switch (upper) {
      case 'PATIENT_INACTIVE':
      case 'INACTIVE_PATIENT':
        return 'Patient is inactive';
      case 'LOW_ACTIVITY':
      case 'PATIENT_LOW_ACTIVITY':
        return 'Patient activity is low';
      case 'MISSED_CHECKIN':
      case 'CHECKIN_MISSED':
        return 'Patient missed a check-in';
      case 'HIGH_RISK':
      case 'HIGH_RISK_PATIENT':
        return 'High-risk patient';
      case 'HIGH_FBS':
      case 'FASTING_BLOOD_SUGAR_HIGH':
        return 'High fasting blood sugar';
      case 'LOW_SUGAR':
      case 'LOW_GLUCOSE':
      case 'HYPOGLYCEMIA':
        return 'Low blood sugar';
      case 'CRITICAL_GLUCOSE':
      case 'HIGH_GLUCOSE':
      case 'HYPERGLYCEMIA':
        return 'Elevated glucose level';
      case 'HIGH_BP':
      case 'HYPERTENSION':
        return 'Elevated blood pressure';
      case 'LOW_BP':
      case 'HYPOTENSION':
        return 'Low blood pressure';
      case 'MISSED_MEDICATION':
      case 'MEDICATION_MISSED':
        return 'Medication missed';
      case 'MEDICATION_CHANGED':
        return 'Medication changed';
      case 'CHAT_ROOM_CREATED':
        return 'Chat room created';
      case 'ALERT_ACKNOWLEDGED':
        return 'Alert acknowledged';
      case 'SYMPTOM_REPORTED':
        return 'Symptoms reported';
      case 'VITALS_ANOMALY':
        return 'Vitals anomaly detected';
      case 'NO_PATIENTS_FOUND':
        return 'No patients found';
      case 'UNABLE_TO_LOAD_ALERTS':
        return 'Unable to load alerts';
      case 'CLINICAL_ATTENTION_REQUIRED':
        return 'Clinical attention required';
      case 'ACTIVE_ALERTS':
        return 'Active alerts';
    }

    // If it's already a clean English title, format to sentence case
    return toSentenceCase(candidate);
  }

  /// Maps alert types / technical identifiers to complete, natural English descriptions.
  /// Handles dynamic day values (e.g. 1 day, 2 days, 3 days, 7 days) and repairs
  /// truncated backend messages (e.g., "Patient has not logged for 3 or mor...").
  static String formatAlertDescription(String? rawType, [String? rawDescription]) {
    final typeUpper = (rawType ?? '').trim().toUpperCase();
    final desc = rawDescription?.trim() ?? '';

    // Check for dynamic "NO_LOG" alerts
    final daysMatch = RegExp(r'NO_LOG_(\d+)_DAY', caseSensitive: false).firstMatch(typeUpper);
    if (daysMatch != null) {
      final days = int.tryParse(daysMatch.group(1)!) ?? 1;
      return _formatNoLogDays(days);
    }

    if (typeUpper == 'NO_LOG_3_DAYS' ||
        desc.toLowerCase().contains('not logged for 3') ||
        desc.toLowerCase().contains('not logged in for 3')) {
      return 'The patient has not logged in for the past 3 days.';
    }

    if (typeUpper == 'NO_LOG_7_DAYS' ||
        desc.toLowerCase().contains('not logged for 7') ||
        desc.toLowerCase().contains('not logged in for 7')) {
      return 'The patient has not logged in for the past 7 days.';
    }

    if (typeUpper == 'NO_LOG_1_DAY' ||
        desc.toLowerCase().contains('not logged for 1 day') ||
        desc.toLowerCase().contains('not logged in for 1 day')) {
      return 'The patient has not logged in for the past day.';
    }

    if (typeUpper == 'NO_LOG_2_DAYS' ||
        desc.toLowerCase().contains('not logged for 2 days') ||
        desc.toLowerCase().contains('not logged in for 2 days')) {
      return 'The patient has not logged in for the past 2 days.';
    }

    // Inspect truncated messages like "Patient has not logged for 3 or mor..."
    if (desc.toLowerCase().contains('not logged for') ||
        desc.toLowerCase().contains('patient has not logged')) {
      final match = RegExp(r'(\d+)\s*or\s*more', caseSensitive: false).firstMatch(desc);
      if (match != null) {
        final days = int.tryParse(match.group(1)!) ?? 3;
        return _formatNoLogDays(days);
      }
      return 'The patient has not logged in for recent consecutive days.';
    }

    // Domain alert type descriptions
    switch (typeUpper) {
      case 'MISSED_CHECKIN':
      case 'CHECKIN_MISSED':
        return 'The patient has missed their scheduled check-in.';
      case 'LOW_ACTIVITY':
      case 'PATIENT_LOW_ACTIVITY':
        return "The patient's activity has been lower than expected.";
      case 'HIGH_RISK':
      case 'HIGH_RISK_PATIENT':
        return 'This patient requires additional clinical attention.';
      case 'PATIENT_INACTIVE':
      case 'INACTIVE_PATIENT':
        return 'The patient has been inactive and may need clinical follow-up.';
      case 'HIGH_FBS':
      case 'FASTING_BLOOD_SUGAR_HIGH':
        if (desc.isNotEmpty && !_isTruncated(desc)) return _sanitizeSentence(desc);
        return "The patient's fasting blood sugar is above the target clinical threshold.";
      case 'LOW_SUGAR':
      case 'LOW_GLUCOSE':
      case 'HYPOGLYCEMIA':
        if (desc.isNotEmpty && !_isTruncated(desc)) return _sanitizeSentence(desc);
        return "The patient's blood sugar has dropped below the safe threshold.";
      case 'CRITICAL_GLUCOSE':
      case 'HIGH_GLUCOSE':
      case 'HYPERGLYCEMIA':
        if (desc.isNotEmpty && !_isTruncated(desc)) return _sanitizeSentence(desc);
        return "The patient's blood glucose reading is significantly elevated.";
      case 'HIGH_BP':
      case 'HYPERTENSION':
        if (desc.isNotEmpty && !_isTruncated(desc)) return _sanitizeSentence(desc);
        return "The patient's blood pressure reading is higher than normal.";
      case 'LOW_BP':
      case 'HYPOTENSION':
        if (desc.isNotEmpty && !_isTruncated(desc)) return _sanitizeSentence(desc);
        return "The patient's blood pressure reading is lower than normal.";
      case 'MISSED_MEDICATION':
      case 'MEDICATION_MISSED':
        return 'The patient missed taking their scheduled medication.';
      case 'CHAT_ROOM_CREATED':
        return 'A clinical discussion chat room has been created.';
      case 'ALERT_ACKNOWLEDGED':
        return 'This alert has been reviewed and acknowledged.';
      case 'SYMPTOM_REPORTED':
        if (desc.isNotEmpty && !_isTruncated(desc)) return _sanitizeSentence(desc);
        return 'The patient has reported new or worsening clinical symptoms.';
    }

    // If description is present, not empty, and not truncated, sanitize into full sentence
    if (desc.isNotEmpty && !_isTruncated(desc)) {
      return _sanitizeSentence(desc);
    }

    if (desc.isNotEmpty && _isTruncated(desc)) {
      // Clean up truncated trailing dots and complete the sentence
      var clean = desc.replaceAll(RegExp(r'\.{2,}$'), '').trim();
      return _sanitizeSentence(clean);
    }

    return 'No additional details are available at this time.';
  }

  static String _formatNoLogDays(int days) {
    if (days <= 1) {
      return 'The patient has not logged in for the past day.';
    }
    return 'The patient has not logged in for the past $days days.';
  }

  static bool _isTruncated(String text) {
    return text.endsWith('...') || text.endsWith('..') || text.endsWith('mor');
  }

  static String _sanitizeSentence(String text) {
    var t = text.trim();
    if (t.isEmpty) return 'No additional details are available at this time.';

    // Capitalize first letter
    t = t[0].toUpperCase() + (t.length > 1 ? t.substring(1) : '');

    // Add trailing period if needed
    if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) {
      t = '$t.';
    }
    return t;
  }

  /// Formats severity labels into clean Sentence case
  static String formatSeverity(String? severity) {
    if (severity == null || severity.isEmpty) return 'Info';
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 'Critical';
      case 'URGENT':
        return 'Urgent';
      case 'HIGH':
        return 'High';
      case 'WATCH':
        return 'Watch';
      case 'MEDIUM':
        return 'Medium';
      case 'LOW':
        return 'Low';
      case 'INFO':
      default:
        return 'Info';
    }
  }

  /// Formats alert status into clean Sentence case
  static String formatAlertStatus(String? status, {bool isAcknowledged = false}) {
    if (isAcknowledged) return 'Acknowledged';
    if (status == null || status.isEmpty) return 'Pending';
    switch (status.toLowerCase()) {
      case 'acknowledged':
        return 'Acknowledged';
      case 'ignored':
        return 'Dismissed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  /// Formats user role into clean Sentence case
  static String formatRole(String? role) {
    if (role == null || role.isEmpty) return 'Clinical staff';
    switch (role.toUpperCase()) {
      case 'DOCTOR':
        return 'Doctor';
      case 'DIETICIAN':
        return 'Dietician';
      case 'STAFF':
        return 'Clinical staff';
      case 'ADMIN':
        return 'Administrator';
      case 'PATIENT':
        return 'Patient';
      default:
        return toSentenceCase(role);
    }
  }

  /// Formats glucose status into clean Sentence case
  static String formatGlucoseStatus(String? status) {
    if (status == null || status.isEmpty) return 'Normal';
    switch (status.toUpperCase()) {
      case 'CRITICAL':
        return 'Critical';
      case 'WARNING':
        return 'Warning';
      case 'NORMAL':
      default:
        return 'Normal';
    }
  }

  /// Formats prescription / medication action into clean Sentence case
  static String formatMedicationAction(String? action) {
    if (action == null || action.isEmpty) return 'New';
    switch (action.toUpperCase()) {
      case 'NEW':
        return 'New';
      case 'CONTINUE':
        return 'Continue';
      case 'MODIFIED':
      case 'INCREASE':
      case 'DECREASE':
        return 'Modified';
      case 'DISCONTINUED':
        return 'Discontinued';
      default:
        return toSentenceCase(action);
    }
  }

  /// Formats prescription status into clean Sentence case
  static String formatPrescriptionStatus(String? status) {
    if (status == null || status.isEmpty) return 'Prescription';
    switch (status.toUpperCase()) {
      case 'SENT':
        return 'Sent';
      case 'DRAFT':
        return 'Draft';
      case 'ACTIVE':
        return 'Active';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return toSentenceCase(status);
    }
  }

  /// Formats clinical note category into clean Sentence case
  static String formatNoteCategory(String? category) {
    if (category == null || category.isEmpty) return 'General clinical note';
    switch (category.toUpperCase()) {
      case 'GENERAL':
        return 'General clinical note';
      case 'DIETARY':
        return 'Dietary guidance';
      case 'MEDICATION':
        return 'Medication review';
      case 'LIFESTYLE':
        return 'Lifestyle & activity';
      case 'CLINICAL':
        return 'Clinical observation';
      case 'DAILY_LOG':
        return 'Daily log observation';
      case 'ALERT':
        return 'Alert observation';
      default:
        return toSentenceCase(category);
    }
  }

  // Common direct database/enum replacements
  static final Map<String, String> _directTextReplacements = {
    'NO_LOG_3_DAYS': 'Patient has not logged in',
    'NO_LOG_7_DAYS': 'Patient has not logged in',
    'NO_LOG_1_DAY': 'Patient has not logged in',
    'NO_LOG_2_DAYS': 'Patient has not logged in',
    'PATIENT_INACTIVE': 'Patient is inactive',
    'LOW_ACTIVITY': 'Patient activity is low',
    'MISSED_CHECKIN': 'Patient missed a check-in',
    'HIGH_RISK': 'High-risk patient',
    'CHAT_ROOM_CREATED': 'Chat room created',
    'USER_NOT_FOUND': 'User not found',
    'INVALID_CREDENTIALS': 'Invalid email or password',
    'SERVER_ERROR': 'Something went wrong. Please try again.',
    'ACTIVE_ALERTS': 'Active alerts',
    'CLINICAL_ATTENTION_REQUIRED': 'Clinical attention required',
    'NO_PATIENTS_FOUND': 'No patients found',
    'UNABLE_TO_LOAD_ALERTS': 'Unable to load alerts',
    'NO_DATA_FOUND': 'No data is available at the moment.',
    'FAILED': 'Unable to complete this action. Please try again.',
    'LOGIN_FAILED': 'Unable to sign in. Please check your email and password.',
  };
}
