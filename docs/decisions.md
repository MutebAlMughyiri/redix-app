[Documentation](README.md) › Decisions

# Decisions

Newest first. Each says what was decided and why; the code and the issues hold the details.

| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-01 | The user guide's screenshots are taken by the Patrol tests | A picture of the real app, never out of date |
| 2026-11-01 | Every public class and member has a doc comment, enforced by `public_member_api_docs` | A contributor understands each method |
| 2026-11-01 | The code holds word keys only, and the phone keeps one language | No word value ships in the app, and the phone holds no more than it shows |
| 2026-11-01 | Words come from the database through the API, not from files in the app | A word changes without an app release |
| 2026-11-01 | Patrol runs the real app end to end against the real API, in CI too | Tests replace manual testing |
| 2026-11-01 | Every element a user sees or acts on has a `Key` constant on its screen | Tests find elements by meaning, never by text |
| 2026-11-01 | Arabic and English from the first release | Both languages are used |
