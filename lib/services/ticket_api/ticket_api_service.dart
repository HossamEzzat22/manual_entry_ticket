import 'package:dio/dio.dart';

import '../../core/network/dio_helper.dart';
import '../log_helper/log_helper.dart';

/// Thin wrapper around the two ManualTicket endpoints, shared by the submit
/// cubit (first attempt) and the offline retry service so the request shape
/// and logging stay identical.
///
/// Both methods return `true` when the server accepted the request and `false`
/// when it responded with `success != true`. They rethrow transport errors
/// (e.g. [DioException]) so the caller can tell "server said no" apart from
/// "couldn't reach the server" — both are treated as a failure to queue.
class TicketApiService {
  static const String _insertUrl = 'api/ManualTicket/InsertEntryTicket';
  static const String _imageUrl = 'api/ManualTicket/UpdateEntryTicketImage';

  static Future<bool> insertEntryTicket({
    required int deviceId,
    required String plate,
    required String ticketNumber,
    // required String token,
    required String entrySyncTime,

  }) async {
    // Server uses [FromForm] → must send as FormData, not JSON.
    final form = FormData.fromMap({
      "deviceId": deviceId,
      "plate": plate,
      "ticketNumber": ticketNumber,
      "entrySyncTime": entrySyncTime,

    });

    await LogHelper.logApiRequest('POST', _insertUrl, data: {
      "deviceId": deviceId,
      "plate": plate,
      "ticketNumber": ticketNumber,
      "entrySyncTime": entrySyncTime,

    });

    final response = await DioHelper.postData(
      url: _insertUrl,
      data: form,
    );

    final body = response.data as Map<String, dynamic>;
    final ok = body['success'] == true;
    if (!ok) {
      await LogHelper.log('API', 'InsertEntryTicket rejected: ${body['message']}');
    }
    return ok;
  }

  static Future<bool> updateEntryTicketImage({
    required int deviceId,
    required String ticketNumber,
    required String base64Image,
    // required String token,
  }) async {
    final form = FormData.fromMap({
      "deviceId": deviceId,
      "ticketNumber": ticketNumber,
      "entryImageBase64": base64Image,
    });

    await LogHelper.logApiRequest('POST', _imageUrl, data: {
      "deviceId": deviceId,
      "ticketNumber": ticketNumber,
      "entryImageBase64": "[base64 length: ${base64Image.length}]",
    });

    final response = await DioHelper.postData(
      url: _imageUrl,
      data: form,
    );

    final body = response.data as Map<String, dynamic>;
    final ok = body['success'] == true;
    if (!ok) {
      await LogHelper.log('IMAGE_UPLOAD', 'Image upload rejected: ${body['message']}');
    }
    return ok;
  }
}
