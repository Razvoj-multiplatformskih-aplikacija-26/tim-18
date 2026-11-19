/// A message that is well formed JSON but cannot be turned into a domain
/// object (an unknown kind, a status without its data, a stored value the
/// domain rejects).
final class MappingException implements Exception {
  const MappingException(this.message);

  final String message;

  @override
  String toString() => 'MappingException($message)';
}
