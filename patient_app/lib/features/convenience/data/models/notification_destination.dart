enum NotificationDestinationType {
  result,
  appointment,
  medication,
  symptom,
  chat,
}

class NotificationDestination {
  const NotificationDestination({required this.type, required this.id});

  final NotificationDestinationType type;
  final String id;
}

abstract final class NotificationDeepLinkParser {
  static NotificationDestination? parse(String? deepLink) {
    final value = deepLink?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    late final List<String> segments;
    try {
      segments = uri.pathSegments;
    } on FormatException {
      return null;
    }

    if (segments.length == 2 && _isValidId(segments[1])) {
      return switch (segments[0]) {
        'results' => NotificationDestination(
          type: NotificationDestinationType.result,
          id: segments[1],
        ),
        'appointments' => NotificationDestination(
          type: NotificationDestinationType.appointment,
          id: segments[1],
        ),
        'symptoms' => NotificationDestination(
          type: NotificationDestinationType.symptom,
          id: segments[1],
        ),
        'chat' => NotificationDestination(
          type: NotificationDestinationType.chat,
          id: segments[1],
        ),
        _ => null,
      };
    }

    if (segments.length == 3 &&
        segments[0] == 'medications' &&
        segments[1] == 'logs' &&
        _isValidId(segments[2])) {
      return NotificationDestination(
        type: NotificationDestinationType.medication,
        id: segments[2],
      );
    }

    return null;
  }

  static bool _isValidId(String value) {
    final id = value.trim();
    return id.isNotEmpty &&
        id == value &&
        !id.contains('{') &&
        !id.contains('}') &&
        !id.contains(RegExp(r'\s'));
  }
}
