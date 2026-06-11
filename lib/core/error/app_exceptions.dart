abstract class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() {
    return "${prefix ?? ''}$message";
  }
}

class ApiException extends AppException {
  final int? statusCode;
  final dynamic responseData;

  ApiException(
    String message, {
    String? prefix = "Errore API: ",
    this.statusCode,
    this.responseData,
  }) : super(message, prefix);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, "Errore di Rete: ");
}

class DatabaseException extends AppException {
  DatabaseException(String message) : super(message, "Errore Database: ");
}

/*
// --- ECCEZIONI DI NETWORK E API ---

/// Errore durante una chiamata API (es. timeout, 500, etc.)

class ApiNetworkException extends AppException {
  ApiNetworkException(String message) : super(message, "Errore di Rete: ");
}

/// Errore nei dati ricevuti dall'API (es. 404, 401, parsing JSON fallito)
class ApiDataException extends AppException {
  ApiDataException(String message) : super(message, "Errore Dati API: ");
}

/// Errore per richiesta non autorizzata (401, 403)
class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message, "Non Autorizzato: ");
}

// --- ECCEZIONI DI DATABASE E STORAGE ---

/// Errore generico del database locale (es. Sqflite)
class DatabaseException extends AppException {
  DatabaseException(String message) : super(message, "Errore Database: ");
}

/// Errore nello storage locale (es. SharedPreferences)
class StorageException extends AppException {
  StorageException(String message) : super(message, "Errore Storage: ");
}
*/
