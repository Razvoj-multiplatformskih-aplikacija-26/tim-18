/// A decoded JSON object.
typedef Json = Map<String, Object?>;

/// Required field of type [T]. A missing or wrongly typed field is a malformed
/// message, reported as [FormatException].
T requiredField<T>(Json json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw FormatException('Polje "$key" nedostaje ili nije tipa $T.');
}

/// Optional field of type [T]: absent and null both give null.
T? optionalField<T extends Object>(Json json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is T) return value;
  throw FormatException('Polje "$key" nije tipa $T.');
}

/// A list of JSON objects under [key].
List<Json> objectList(Json json, String key) {
  final value = requiredField<List<Object?>>(json, key);
  return [
    for (final item in value)
      if (item is Map<String, Object?>) item else throw FormatException('Element liste "$key" nije objekat.'),
  ];
}
