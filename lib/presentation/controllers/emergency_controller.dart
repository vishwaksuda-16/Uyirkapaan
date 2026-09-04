import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/emergency_request.dart';
import '../../domain/entities/emergency_type.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/repositories/emergency_request_repository.dart';

enum SubmissionState {
  idle,
  submitting,
  active,
  completed,
  cancelled,
  error,
}

/// Primary Controller managing the emergency reporting workflow, form validation,
/// request submission, real-time lifecycle tracking, and persistent session recovery.
class EmergencyController extends ChangeNotifier {
  final EmergencyRequestRepository repository;

  // Form State
  EmergencyType _selectedType = EmergencyType.accident;
  int _victimCount = AppConstants.defaultVictims;
  String _additionalNotes = '';

  // Active Lifecycle State
  SubmissionState _submissionState = SubmissionState.idle;
  EmergencyRequest? _activeRequest;
  String? _errorMessage;
  StreamSubscription<EmergencyRequest>? _requestSubscription;

  // Timers
  DateTime? _t0ClientPressTime;

  EmergencyController({required this.repository}) {
    // Attempt session recovery on startup
    recoverActiveSession();
  }

  // Getters
  EmergencyType get selectedType => _selectedType;
  int get victimCount => _victimCount;
  String get additionalNotes => _additionalNotes;
  SubmissionState get submissionState => _submissionState;
  EmergencyRequest? get activeRequest => _activeRequest;
  String? get errorMessage => _errorMessage;
  bool get hasActiveRequest => _activeRequest != null && _activeRequest!.status.isActive;

  // Form Mutators
  void setEmergencyType(EmergencyType type) {
    _selectedType = type;
    notifyListeners();
  }

  void setVictimCount(int count) {
    if (count >= AppConstants.minVictims && count <= AppConstants.maxVictims) {
      _victimCount = count;
      notifyListeners();
    }
  }

  void incrementVictimCount() {
    if (_victimCount < AppConstants.maxVictims) {
      _victimCount++;
      notifyListeners();
    }
  }

  void decrementVictimCount() {
    if (_victimCount > AppConstants.minVictims) {
      _victimCount--;
      notifyListeners();
    }
  }

  void setAdditionalNotes(String notes) {
    _additionalNotes = notes;
    notifyListeners();
  }

  /// Records client-side T0 timestamp when user presses "Request Ambulance".
  void markT0Timestamp() {
    _t0ClientPressTime = DateTime.now();
  }

  /// Validates input and submits the emergency request through the repository.
  Future<bool> submitEmergencyRequest({
    required LocationData emergencyLocation,
    LocationData? requesterLocation,
  }) async {
    // 1. Validation
    if (_victimCount < AppConstants.minVictims) {
      _errorMessage = 'Victim count must be at least ${AppConstants.minVictims}';
      notifyListeners();
      return false;
    }

    _submissionState = SubmissionState.submitting;
    _errorMessage = null;
    notifyListeners();

    final t0 = _t0ClientPressTime ?? DateTime.now();

    final draft = EmergencyRequest(
      requestId: '', // Will be assigned by backend/mock
      requesterId: '',
      emergencyType: _selectedType,
      victimCount: _victimCount,
      emergencyLocation: emergencyLocation,
      requesterLocation: requesterLocation,
      createdAt: DateTime.now(),
      status: RequestStatus.created,
      additionalNotes: _additionalNotes.isNotEmpty ? _additionalNotes : null,
      t0UserPressed: t0,
    );

    try {
      final created = await repository.submitEmergencyRequest(draft);
      _activeRequest = created;
      _submissionState = SubmissionState.active;
      _subscribeToUpdates(created.requestId);
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _submissionState = SubmissionState.error;
      _errorMessage = f.message;
      notifyListeners();
      return false;
    } catch (e) {
      _submissionState = SubmissionState.error;
      _errorMessage = 'Failed to create emergency request: $e';
      notifyListeners();
      return false;
    }
  }

  /// Recovers an active request from local storage if the app was closed during an emergency.
  Future<void> recoverActiveSession() async {
    try {
      final persistedId = await repository.getActivePersistedRequestId();
      if (persistedId != null && persistedId.isNotEmpty) {
        final existing = await repository.getEmergencyRequest(persistedId);
        if (existing.status.isActive) {
          _activeRequest = existing;
          _submissionState = SubmissionState.active;
          _subscribeToUpdates(persistedId);
          notifyListeners();
        } else {
          await repository.clearActivePersistedRequest();
        }
      }
    } catch (_) {
      // If recovery fails (e.g. invalid cached id), gracefully clear it
      await repository.clearActivePersistedRequest();
    }
  }

  /// Cancels the currently active emergency request.
  Future<bool> cancelActiveRequest({String? reason}) async {
    if (_activeRequest == null) return false;

    try {
      final cancelled = await repository.cancelEmergencyRequest(
        _activeRequest!.requestId,
        reason: reason,
      );
      _activeRequest = cancelled;
      _submissionState = SubmissionState.cancelled;
      _unsubscribe();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel request: $e';
      notifyListeners();
      return false;
    }
  }

  /// Resets controller state for creating a new emergency request.
  void resetForm() {
    _unsubscribe();
    _submissionState = SubmissionState.idle;
    _activeRequest = null;
    _errorMessage = null;
    _victimCount = AppConstants.defaultVictims;
    _selectedType = EmergencyType.accident;
    _additionalNotes = '';
    _t0ClientPressTime = null;
    notifyListeners();
  }

  void _subscribeToUpdates(String requestId) {
    _unsubscribe();
    _requestSubscription = repository.watchRequestUpdates(requestId).listen(
      (updatedRequest) {
        _activeRequest = updatedRequest;
        if (updatedRequest.status == RequestStatus.completed) {
          _submissionState = SubmissionState.completed;
        } else if (updatedRequest.status == RequestStatus.cancelled) {
          _submissionState = SubmissionState.cancelled;
        }
        notifyListeners();
      },
      onError: (error) {
        // Keep active state on transient stream errors
      },
    );
  }

  void _unsubscribe() {
    _requestSubscription?.cancel();
    _requestSubscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
