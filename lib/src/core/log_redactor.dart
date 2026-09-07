class LogRedactor {
  const LogRedactor();

  static final _uuid = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );
  static final _urlCredentials =
      RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://)[^@\s]+@');
  static final _sensitiveQuery = RegExp(
    r'([?&](?:token|access_token|password|passwd|key|secret)=)[^&#\s]+',
    caseSensitive: false,
  );
  static final _ansiEscape = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

  String redact(String input) => input
      .replaceAll(_ansiEscape, '')
      .replaceAll(_uuid, '[redacted-uuid]')
      .replaceAllMapped(_urlCredentials, (match) => '${match[1]}[redacted]@')
      .replaceAllMapped(_sensitiveQuery, (match) => '${match[1]}[redacted]');
}
