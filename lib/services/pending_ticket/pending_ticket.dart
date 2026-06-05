/// A ticket submission that did not fully reach the server and is queued in
/// SQLite for retry.
///
/// [needsInsert] / [needsImage] track which of the two API calls still has to
/// succeed. A row is deleted once both are done.
class PendingTicket {
  final int? id;
  final int deviceId;
  final String plate;
  final String ticketNumber;
  final String? base64Image;
  final bool needsInsert;
  final bool needsImage;
  final int attempts;
  final String? lastError;
  final String createdAt;

  const PendingTicket({
    this.id,
    required this.deviceId,
    required this.plate,
    required this.ticketNumber,
    required this.base64Image,
    required this.needsInsert,
    required this.needsImage,
    this.attempts = 0,
    this.lastError,
    required this.createdAt,
  });

  PendingTicket copyWith({
    bool? needsInsert,
    bool? needsImage,
    int? attempts,
    String? lastError,
  }) {
    return PendingTicket(
      id: id,
      deviceId: deviceId,
      plate: plate,
      ticketNumber: ticketNumber,
      base64Image: base64Image,
      needsInsert: needsInsert ?? this.needsInsert,
      needsImage: needsImage ?? this.needsImage,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'deviceId': deviceId,
        'plate': plate,
        'ticketNumber': ticketNumber,
        'base64Image': base64Image,
        'needsInsert': needsInsert ? 1 : 0,
        'needsImage': needsImage ? 1 : 0,
        'attempts': attempts,
        'lastError': lastError,
        'createdAt': createdAt,
      };

  factory PendingTicket.fromMap(Map<String, dynamic> map) => PendingTicket(
        id: map['id'] as int?,
        deviceId: map['deviceId'] as int,
        plate: map['plate'] as String,
        ticketNumber: map['ticketNumber'] as String,
        base64Image: map['base64Image'] as String?,
        needsInsert: (map['needsInsert'] as int) == 1,
        needsImage: (map['needsImage'] as int) == 1,
        attempts: map['attempts'] as int? ?? 0,
        lastError: map['lastError'] as String?,
        createdAt: map['createdAt'] as String,
      );
}
