/// What the API says a user may do, named as the API names it. The app shows a control from these, and a project manager ticks them for each person in a project.
enum Permission {
  /// See the registered projects, and approve or reject them: the admin's, never ticked in a project.
  approveProjects,

  /// See a project and everything in it: being in the project.
  readProject,

  /// Add people to a project and tick their permissions.
  manageUsers,

  /// See every partner in a project and their capital, not only their own, and take the report files.
  seeAllCapital,

  /// Rename a project, add and delete its units, keep its documents and close it.
  manageProject,

  /// Shape a project's expense structure: its categories, items, subgroups and columns.
  manageStructure,

  /// Keep a project's payment methods, accounts, partners, suppliers and contracts.
  manageSettings,

  /// Add a supplier to a project's register; without [manageSettings] it waits for approval.
  addSupplier,

  /// Spend from any account of a project; without it, only from the accounts in one's custody.
  chargeAnyAccount,

  /// Record a purchase or a contractor payment in a project's ledger.
  recordEntries,

  /// Change or send an entry someone else entered, or one waiting, before it is approved.
  manageAnyEntry,

  /// Delete an entry not yet approved: one's own, or with [manageAnyEntry] anyone's.
  deleteEntries,

  /// Keep a picture or a file in a project, for an entry, a receipt or a contract.
  attachFiles,

  /// See the entries waiting in a project, approve or reject them, and reverse an approved one.
  approveEntries,

  /// Enter what counts at once in a project: transfers, capital movements, revenue and reconciling.
  moveMoney;

  /// What can be ticked in a project, in this order: every permission but the system's own.
  static List<Permission> get inAProject => values.where((permission) => permission != approveProjects).toList();

  /// The key of the word naming it.
  String get wordKey => 'permissions.$name';

  /// The key of the word explaining it.
  String get hintKey => 'permissions.${name}Hint';
}
