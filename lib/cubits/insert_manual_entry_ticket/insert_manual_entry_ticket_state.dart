part of 'insert_manual_entry_ticket_cubit.dart';

sealed class InsertManualEntryTicketState {}

final class InsertManualEntryTicketInitial extends InsertManualEntryTicketState {}

final class InsertManualEntryTicketLoadingState extends InsertManualEntryTicketState {}

// Emitted while uploading the image after ticket insert succeeds
final class InsertManualEntryTicketImageUploadingState extends InsertManualEntryTicketState {}

final class InsertManualEntryTicketSuccessState extends InsertManualEntryTicketState {
  final String ticketNo;
  final String plate;
  final int facilityId;
  final int carParkId;
  final int clientId;
  final String entryTime;
  final String status;

  InsertManualEntryTicketSuccessState({
    required this.ticketNo,
    required this.plate,
    required this.facilityId,
    required this.carParkId,
    required this.clientId,
    required this.entryTime,
    required this.status,
  });
}

final class InsertManualEntryTicketErrorState extends InsertManualEntryTicketState {
  final String message;
  InsertManualEntryTicketErrorState({required this.message});
}