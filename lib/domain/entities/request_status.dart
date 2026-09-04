import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Complete lifecycle state of an EmergencyRequest.
enum RequestStatus {
  created(
    code: 'CREATED',
    userMessage: 'Request Created',
    userDescription: 'Emergency request registered. Preparing dispatch...',
    color: AppColors.statusSearching,
    isActive: true,
  ),
  searching(
    code: 'SEARCHING',
    userMessage: 'Searching for Ambulance',
    userDescription: 'Finding the nearest available emergency vehicle...',
    color: AppColors.statusSearching,
    isActive: true,
  ),
  assigned(
    code: 'ASSIGNED',
    userMessage: 'Ambulance Assigned',
    userDescription: 'Ambulance assigned. Awaiting driver response...',
    color: AppColors.statusAssigned,
    isActive: true,
  ),
  accepted(
    code: 'ACCEPTED',
    userMessage: 'Driver Accepted',
    userDescription: 'Ambulance driver has confirmed and is preparing to depart.',
    color: AppColors.statusAccepted,
    isActive: true,
  ),
  enRouteToPatient(
    code: 'EN_ROUTE_TO_PATIENT',
    userMessage: 'Ambulance is on the way',
    userDescription: 'Ambulance is actively traveling to your emergency location.',
    color: AppColors.statusEnRoute,
    isActive: true,
  ),
  arrivedAtPatient(
    code: 'ARRIVED_AT_PATIENT',
    userMessage: 'Ambulance Arrived at Scene',
    userDescription: 'Paramedics have reached the emergency location.',
    color: AppColors.statusArrived,
    isActive: true,
  ),
  patientOnboard(
    code: 'PATIENT_ONBOARD',
    userMessage: 'Patient Onboard',
    userDescription: 'Patient is receiving medical care inside the ambulance.',
    color: AppColors.statusEnRoute,
    isActive: true,
  ),
  enRouteToHospital(
    code: 'EN_ROUTE_TO_HOSPITAL',
    userMessage: 'En Route to Hospital',
    userDescription: 'Ambulance is navigating to the destination hospital.',
    color: AppColors.statusEnRoute,
    isActive: true,
  ),
  arrivedAtHospital(
    code: 'ARRIVED_AT_HOSPITAL',
    userMessage: 'Arrived at Hospital',
    userDescription: 'Ambulance has safely reached the emergency ward.',
    color: AppColors.statusCompleted,
    isActive: true,
  ),
  completed(
    code: 'COMPLETED',
    userMessage: 'Emergency Completed',
    userDescription: 'The emergency response case has been successfully closed.',
    color: AppColors.statusCompleted,
    isActive: false,
  ),
  cancelled(
    code: 'CANCELLED',
    userMessage: 'Request Cancelled',
    userDescription: 'This emergency request was cancelled by the requester or operator.',
    color: AppColors.statusCancelled,
    isActive: false,
  ),
  noAmbulanceAvailable(
    code: 'NO_AMBULANCE_AVAILABLE',
    userMessage: 'No Ambulance Available',
    userDescription: 'All local emergency vehicles are currently busy. Please call emergency services immediately.',
    color: AppColors.emergencyRed,
    isActive: false,
  );

  final String code;
  final String userMessage;
  final String userDescription;
  final Color color;
  final bool isActive;

  const RequestStatus({
    required this.code,
    required this.userMessage,
    required this.userDescription,
    required this.color,
    required this.isActive,
  });

  static RequestStatus fromCode(String code) {
    return RequestStatus.values.firstWhere(
      (s) => s.code.toUpperCase() == code.toUpperCase(),
      orElse: () => RequestStatus.searching,
    );
  }
}
