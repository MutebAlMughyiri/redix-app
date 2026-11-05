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
}
