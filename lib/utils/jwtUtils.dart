import 'dart:convert';

Map<String, dynamic>? _decodePayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      // Bukan format JWT yang valid
      return null;
    }
    String payloadBase64 = parts[1];
    // Normalisasi Base64Url (mengganti - dengan +, _ dengan / dan menambahkan padding jika perlu)
    // Padding diperlukan agar base64.decode berfungsi dengan benar
    String normalizedSource = base64Url.normalize(payloadBase64);
    String decodedPayload = utf8.decode(base64Url.decode(normalizedSource));
    return json.decode(decodedPayload) as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
}

bool isTokenExpired(String token) {
  final payload = _decodePayload(token);
  if (payload == null || !payload.containsKey('exp')) {
    // Jika tidak bisa decode atau tidak ada claim 'exp', anggap saja expired atau tidak valid
    return true;
  }

  try {
    final expirationTimeInSeconds = payload['exp'] as int;
    final currentTimeInSeconds = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    return expirationTimeInSeconds < currentTimeInSeconds;
  } catch (e) {
    return true;
  }
}