// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../words/words.dart';

/// The two pages the API serves to anyone, in Arabic and English (redix-api #143 R3, R4, R7): opened in the phone's browser, so the app shows
/// the one copy the stores link to and never keeps a second.
enum LegalPage {
  /// The privacy policy: what REDIX keeps about a person, why, where, how long, who sees it, and how to ask for its removal.
  privacy('/privacy', 'legal.privacy'),

  /// The terms of use of the app as installed.
  terms('/terms', 'legal.terms');

  const LegalPage(this.path, this.wordKey);

  /// Where the API serves it.
  final String path;

  /// The word key of its name, which also keys whatever opens it.
  final String wordKey;

  /// The key of whatever opens it.
  Key get key => Key(wordKey);

  /// What it is called, in the language in use.
  String nameIn(Words words) => words.text(wordKey);

  /// Opens it in the phone's browser.
  Future<void> open() => launchUrl(Uri.parse('$apiBaseUrl$path'), mode: LaunchMode.externalApplication);
}

/// What registering agrees to (redix-api #143 R7): one sentence, then a link to each page, shown before an account is made.
class LegalAgreement extends StatelessWidget {
  /// The agreement, shown on registering a project from the sign-in page.
  const LegalAgreement({super.key});

  /// The sentence.
  static const sentenceKey = Key('legal.agreement');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(words.legalAgreement, key: sentenceKey, style: Theme.of(context).textTheme.bodySmall),
        Wrap(children: [for (final page in LegalPage.values) TextButton(key: page.key, onPressed: page.open, child: Text(page.nameIn(words)))]),
      ],
    );
  }
}
