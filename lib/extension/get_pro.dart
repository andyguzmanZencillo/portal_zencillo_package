extension JsonExtensionProSe on Map<String, dynamic> {
  T getPro<T>(String key, T defaultValue) {
    final lowerCaseKey = key.toLowerCase();

    dynamic value;
    for (var entry in entries) {
      if (entry.key.toLowerCase() == lowerCaseKey) {
        value = entry.value;
        break;
      }
    }

    // Si no se encuentra la clave, devolver el valor por defecto
    if (value == null) return defaultValue;

    // Manejo especial de tipos
    if (T == DateTime) {
      return (value is String ? DateTime.tryParse(value) : null) as T? ??
          defaultValue;
    }

    if (T == String) {
      return value.toString() as T;
    }

    if (T == int) {
      return (value is num ? value.toInt() : int.tryParse(value.toString()))
              as T? ??
          defaultValue;
    }

    if (T == double) {
      return (value is num
              ? value.toDouble()
              : double.tryParse(value.toString())) as T? ??
          defaultValue;
    }

    return value is T ? value : defaultValue;
  }
}
