import '../services/api_service.dart';

class UserErrorMessages {
  const UserErrorMessages._();

  static const offlineTitle = 'لا يوجد اتصال بالإنترنت';
  static const offlineDescription =
      'تعذر تحميل البيانات حاليًا. تأكد من اتصالك بالإنترنت ثم حاول مرة أخرى.';
  static const inlineRetryDescription =
      'تحقق من اتصال الإنترنت ثم أعد المحاولة.';
  static const genericError = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  static const dataLoadError = 'تعذر تحميل البيانات حاليًا. حاول مرة أخرى.';

  static String fromApiException(
    ApiException error, {
    String fallback = genericError,
  }) {
    final details = <String>[
      error.message,
      if (error.errorMessages.isNotEmpty) error.errorMessages.join('\n'),
      if (error.responseBody != null) error.responseBody.toString(),
      if (error.cause != null) error.cause.toString(),
    ].join('\n');

    if (isNetworkError(details)) {
      return offlineDescription;
    }

    final message = error.errorMessages.isNotEmpty
        ? error.errorMessages.join('\n')
        : error.message;
    return sanitize(message, fallback: fallback);
  }

  static String sanitize(
    String? message, {
    String fallback = genericError,
  }) {
    final normalized = message?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }

    if (isNetworkError(normalized)) {
      return offlineDescription;
    }

    if (_containsTechnicalDetails(normalized)) {
      return fallback;
    }

    return normalized;
  }

  static bool isNetworkError(String? value) {
    final normalized = value?.toLowerCase();
    if (normalized == null || normalized.trim().isEmpty) {
      return false;
    }

    return _containsAny(normalized, const [
      'socketexception',
      'failed host lookup',
      'os error',
      'network is unreachable',
      'connection refused',
      'connection reset',
      'connection timed out',
      'clientexception',
      'xmlhttprequest',
      'no address associated with hostname',
      'تعذر الاتصال بالإنترنت',
      'لا يوجد اتصال بالإنترنت',
      'انتهت مهلة الاتصال',
      'تعذر إتمام الاتصال',
    ]);
  }

  static bool _containsTechnicalDetails(String value) {
    final normalized = value.toLowerCase();
    return _containsAny(normalized, const [
      'api/',
      'http://',
      'https://',
      'malaz.runasp.net',
      'apiexception',
      'exception:',
      'formatexception',
      'unexpected response shape',
      'invalid child response',
      'statuscode:',
      'responsebody:',
      'stacktrace',
      'address:',
      'port:',
    ]);
  }

  static bool _containsAny(String value, List<String> patterns) {
    for (final pattern in patterns) {
      if (value.contains(pattern)) {
        return true;
      }
    }

    return false;
  }
}
