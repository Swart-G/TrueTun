class LogRedactor {
  const LogRedactor();

  String redact(String input) {
    var output = input.replaceAll(_ansi, '');
    output = output.replaceAll(_uuid, '[redacted-uuid]');
    output = output.replaceAllMapped(
      _sensitiveQuery,
      (match) => '${match.group(1)}[redacted]',
    );
    return output;
  }

  static final RegExp _ansi = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
  static final RegExp _uuid = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
  );
  static final RegExp _sensitiveQuery = RegExp(
    r'([?&](?:token|access_token|auth|password|passwd|secret|key|pbk|sid)=)[^&#\s]+',
    caseSensitive: false,
  );
}
