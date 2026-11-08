/// Where an entry stands, named as the API names it (findings row 163).
enum EntryStatus {
  /// Saved by who entered it, and seen by nobody's inbox.
  draft,

  /// Waiting for a decision.
  pendingApproval,

  /// Approved: it counts in every total, and never changes again.
  approved,

  /// Rejected, with a reason, to be fixed and sent again.
  rejected;

  /// The key of the word that says it.
  String get wordKey => 'entries.$name';
}
