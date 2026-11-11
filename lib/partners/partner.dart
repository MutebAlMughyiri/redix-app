/// A partner in a project, as the API answers them. Their own login only says whose account they are; who sees their capital is ticked on people's permissions (redix-api #106).
class Partner {
  /// The partner the API describes in [json].
  Partner.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      userId = json['userId'] as String,
      userName = json['userName'] as String,
      mayDelete = json['mayDelete'] as bool,
      othersDrafts = [for (final author in json['othersDrafts'] as List<dynamic>) author as String],
      myDrafts = [for (final draft in json['myDrafts'] as List<dynamic>) PartnerDraft.fromJson(draft as Map<String, dynamic>)];

  /// No partner yet, for the dialog that adds one.
  Partner.none() : id = '', name = '', userId = '', userName = '', mayDelete = false, othersDrafts = const [], myDrafts = const [];

  /// The partner's id; empty for a partner not added yet.
  final String id;

  /// The partner's name, as it was typed.
  final String name;

  /// The partner's own login; empty for a partner with no login.
  final String userId;

  /// That login's name; empty for a partner with no login.
  final String userName;

  /// True when the signed-in person may delete them: at zero capital with nothing waiting and no one else's draft (redix-api #100, findings row 199); the API decides it.
  final bool mayDelete;

  /// Who else holds a draft naming them, which keeps Delete gray until it is sent or deleted (findings row 199).
  final List<String> othersDrafts;

  /// The signed-in person's own drafts naming them, which deleting them deletes too (findings row 199).
  final List<PartnerDraft> myDrafts;
}

/// One of the signed-in person's own drafts naming a partner (findings row 199).
class PartnerDraft {
  /// The draft the API describes in [json].
  PartnerDraft.fromJson(Map<String, dynamic> json) : entryDate = DateTime.parse(json['entryDate'] as String), amount = (json['amount'] as num).toDouble();

  /// The draft's date.
  final DateTime entryDate;

  /// Its amount.
  final double amount;
}
