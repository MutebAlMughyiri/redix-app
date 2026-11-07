/// An entry waiting on this phone for the network (UC-029).
class PendingEntry {
  /// An entry of [ownerId] in [projectId], for the API [route], holding what was entered in [body], with the file [fileName] if it has one that was not sent yet.
  PendingEntry({required this.ownerId, required this.projectId, required this.route, required this.body, this.fileName = '', this.refusal = ''});

  /// An entry as it was kept.
  PendingEntry.fromJson(Map<String, dynamic> json)
    : ownerId = json['ownerId'] as String,
      projectId = json['projectId'] as String,
      route = json['route'] as String,
      body = Map<String, Object>.from(json['body'] as Map<String, dynamic>),
      fileName = json['fileName'] as String,
      refusal = json['refusal'] as String;

  /// Who entered it: only they send it.
  final String ownerId;

  /// The project it belongs to.
  final String projectId;

  /// `expenses` or `contractor-payments`.
  final String route;

  /// What is sent.
  final Map<String, Object> body;

  /// The name of its file on the phone; empty once sent, or when it has none.
  String fileName;

  /// The word key of why the API refused it; empty while it waits.
  String refusal;

  /// The id made on the phone, which keeps a retried upload from landing twice.
  String get id => body['id']! as String;

  /// True when it was refused and waits for the person, not for the network.
  bool get isRefused => refusal.isNotEmpty;

  /// The date it carries.
  String get date => (body['invoiceDate'] ?? body['paymentDate'] ?? '') as String;

  /// The amount it carries.
  num get amount => (body['amount'] ?? 0) as num;

  /// The entry as it is kept.
  Map<String, Object> toJson() => {'ownerId': ownerId, 'projectId': projectId, 'route': route, 'body': body, 'fileName': fileName, 'refusal': refusal};
}
