/// What a user is in one project (FR-36), each role knowing its word so no reader needs to tell them apart.
enum ProjectRole {
  /// Approves entries and issues the reports.
  financeSupervisor('users.roleFinance'),

  /// Records expenses and invoices.
  fieldSupervisor('users.roleField'),

  /// The least a user can be given.
  reader('users.roleReader');

  const ProjectRole(this.wordKey);

  /// The key of the word that names this role.
  final String wordKey;
}
