// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../api_list.dart';
import '../auth/session.dart';
import '../ui/arabic_spelling.dart';
import '../words/words.dart';

/// One line of a history: what was done, by whom and when (redix-app #89, #101).
abstract interface class HistoryLine {
  /// Its History row, which the next page starts after.
  int get id;

  /// What shows beside it.
  IconData get icon;

  /// What it says, in [words].
  String textIn(Words words);

  /// Who did it and when, in [words].
  String whoAndWhenIn(Words words);
}

/// A history, newest first, a page at a time: of every thing it covers or one, everyone's lines or one person's, and only those holding what was typed, as the API
/// searches them (redix-app #104). The one owner of filtering, searching and paging a history, which every history is (redix-app #101, redix-api #86).
abstract class HistoryList<T extends HistoryLine> extends ApiList<T> {
  /// The history read from [path], filtered by the query parameter [choiceName], seen through [_session].
  HistoryList(this._session, this.path, this.choiceName, T Function(Map<String, dynamic>) fromJson) : super(_session, _pathOf(path, choiceName, '', '', '', 0), 'history', fromJson);

  final Session _session;

  /// How many lines a page holds, as the API gives them.
  static const pageSize = 50;

  /// The route the history is read from.
  final String path;

  /// The query parameter naming the one thing whose lines show.
  final String choiceName;

  var _chosenId = '';
  var _by = '';
  var _text = '';

  static String _pathOf(String path, String choiceName, String chosenId, String by, String text, int before) =>
      Uri(path: path, queryParameters: {choiceName: chosenId, if (by.isNotEmpty) 'by': by, 'before': '$before', if (text.isNotEmpty) 'text': text}).toString();

  /// The thing whose lines show; empty for every one.
  String get chosenId => _chosenId;

  /// The person whose lines alone show; empty for everyone's.
  String get by => _by;

  /// The signed-in user, whom the person chip offers as «أنا».
  String get myId => _session.userId;

  /// True while a filter narrows the lines, so the title bar's filter icon says so (redix-app #104, R6).
  bool get isFiltered => _chosenId.isNotEmpty || _by.isNotEmpty;

  /// True while the last page read was full, so another may follow.
  bool get mayHaveMore => all.isNotEmpty && all.length % pageSize == 0;

  /// Shows every line from the newest, nothing filtered or typed, as a history screen opens: a search does not outlive its screen.
  Future<void> open() {
    _chosenId = '';
    _by = '';
    _text = '';
    return _readNewest();
  }

  /// Shows the lines of [chosenId], or of every one when empty, and only those the person [by] wrote, or everyone's when empty, from the newest, still holding what
  /// was typed.
  Future<void> filter(String chosenId, String by) {
    _chosenId = chosenId;
    _by = by;
    return _readNewest();
  }

  /// Shows only the lines holding [typed], in Western digits as the API reads them, from the newest, keeping the filters.
  Future<void> search(String typed) {
    _text = typedForApi(typed);
    return _readNewest();
  }

  Future<void> _readNewest() {
    pointAt(_pathOf(path, choiceName, _chosenId, _by, _text, 0));
    return load();
  }

  /// Adds the next page after the last line shown; returns an empty string once added, otherwise the word key saying it could not be read.
  Future<String> more() => loadMore(_pathOf(path, choiceName, _chosenId, _by, _text, all.last.id));
}
