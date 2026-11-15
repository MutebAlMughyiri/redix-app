/// What a file is to the entry it is on, named as the API names it, with the word key that names it on the entry's page (redix-app #115, AC-46.10g, D5).
enum EntryAttachmentRole {
  /// A purchase's invoice.
  invoice('entries.fileInvoice'),

  /// A contractor payment's receipt voucher.
  receipt('entries.fileReceipt'),

  /// A partner's money's transfer receipt.
  bankReceipt('entries.fileBankReceipt'),

  /// Anything else: revenue's file, or one put on an entry whose table the project no longer offers.
  other('entries.fileOther');

  const EntryAttachmentRole(this.wordKey);

  /// The key of the word that names it.
  final String wordKey;
}
