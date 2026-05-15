enum ServerStatusKind { notConfigured, unknown, checking, connected, problem }

class ServerStatus {
  const ServerStatus(this.kind, [this.message]);

  const ServerStatus.notConfigured() : this(ServerStatusKind.notConfigured);
  const ServerStatus.unknown() : this(ServerStatusKind.unknown);
  const ServerStatus.checking() : this(ServerStatusKind.checking);
  const ServerStatus.connected() : this(ServerStatusKind.connected);
  const ServerStatus.problem(String message)
    : this(ServerStatusKind.problem, message);

  final ServerStatusKind kind;
  final String? message;

  bool get isConnected => kind == ServerStatusKind.connected;

  String get label {
    switch (kind) {
      case ServerStatusKind.notConfigured:
        return 'Not connected';
      case ServerStatusKind.unknown:
        return 'Unknown';
      case ServerStatusKind.checking:
        return 'Checking...';
      case ServerStatusKind.connected:
        return 'Connected';
      case ServerStatusKind.problem:
        return message ?? 'Not connected';
    }
  }
}
