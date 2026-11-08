[Documentation](../README.md) › UC-070

# UC-070: Request timeouts from a config table

**What it is for:** giving up on a request that gets no answer after a time the API decides, so the phone says there is no connection instead of waiting for ever; a file gets its own, longer time.
**Who uses it:** nobody chooses it: the app reads the values at start, before anyone signs in.
**Issue:** redix-api #94.

## What happens

At start the app reads `GET /config`, which answers without a session, and keeps the values for the next start. `AppConfig` owns them: `requestTimeout` for any request, `fileTimeout` for a file sent or read (an invoice, a document, a report's file). Every request goes through `timed()`, which gives up after its time. Until the values were ever read, a request waits as long as the phone lets it.

## API calls

| Call | When |
| --- | --- |
| `GET /config` | At every start; without a network the kept values stay |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| The values the API answers are taken, and kept for the next start | `AppConfig` | `app_config_test.dart`: UC-070: the values the API answers are taken |
| Without a network the kept values stay | `AppConfig` | `app_config_test.dart`: UC-070: without a network the kept values stay |
| A request with no answer is given up after its time, a file after its own | `timed`, `AppConfig.requestTimeout`, `fileTimeout` | `app_config_test.dart`: UC-070: a request with no answer is given up after its time |
| Before the config was ever read a request waits as long as the phone lets it | `AppConfig` | `app_config_test.dart`: UC-070: before the config was ever read |
