# REDIX app

The mobile app of REDIX (Real Estate Development Intelligence): Flutter for Android, iPhone and Huawei, in Arabic and English. The API is the `redix-api` repo.

- **The business:** the BRS (https://claude.ai/artifact/JJPc1nSe6ekignSgXUpYB4, private). What to build is in this repo's issues: features, and use cases titled `UC-NNN` in build order. The same number in `redix-api` is the same slice of the app.
- **Words:** every word the app shows comes from the API through `Words.of(context)`; the code holds only word keys, never values. The glossary of terms is the issue "Translations: English terms and their Arabic".
- **Findings:** every gap, bug and finding, from either repo, goes into the pinned redix-api issue "Findings: open gaps, bugs and decisions" as a row, never only into a chat.
- **Before writing any code:** read `docs/ARCHITECTURE.md` and the `redix-code-standard` skill in `.claude/skills/`.
