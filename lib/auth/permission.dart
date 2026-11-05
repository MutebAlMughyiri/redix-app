/// What the API says a user may do, named as the API names it. The app shows a control from these, and never knows what a role may do, so a change to a role
/// in the database reaches the app with no release. Each use case adds the ones its screens ask about.
enum Permission {
  /// See the registered projects, and approve or reject them.
  approveProjects,

  /// Add people to a project and give their roles.
  manageUsers,

  /// Add units to a project and close it.
  manageProject,

  /// Shape a project's expense structure: its categories, items, subgroups and columns.
  manageStructure,

  /// Keep a project's payment methods, VAT rate, accounts and partners.
  manageSettings,

  /// Add a supplier to a project's register; without [manageSettings] it waits for approval.
  addSupplier,

  /// Record a purchase in a project's ledger.
  recordEntries,

  /// Keep a picture or a PDF in a project, for an entry or a contract.
  attachFiles,

  /// See every partner in a project and their capital, not only their own.
  seeAllCapital,

  /// See the entries waiting in a project, and approve or reject them.
  approveEntries,

  /// Change or send an entry someone else entered, before it is approved.
  manageAnyEntry,
}
