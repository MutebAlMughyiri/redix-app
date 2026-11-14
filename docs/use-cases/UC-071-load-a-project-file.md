[Documentation](../README.md) › UC-071

# UC-071: Load a project file

**What it is for:** bringing a project that lived in Excel into REDIX in one step (FR-53, BR-43): its manager picks the project's JSON file, and REDIX adds the tables it names, records and approves every row through the same rules as Add entry, enters the actual balances and issues the file's report. One refused row, and nothing is saved.
**Who uses it:** the manager who created the project, who holds `manageProject` (D1), into an open project that holds no entry yet (D4).
**Issue:** redix-api #132 "Load a project's JSON file into REDIX: its structure, entries, actual balances and last report"; the API side is redix-api's UC-071.

## Screens

**تحميل ملف المشروع** in the project's settings on its home, where importing its settings was (D2) ([guide](../guide/project-file.md)):

| Element | `Key` | Does |
| --- | --- | --- |
| تحميل ملف المشروع | `HomeScreen.loadFileKey(id)` | Opens the phone's files for a `.json`; gray without `manageProject`, on a closed project, and once the project holds an entry (`Project.mayLoadFile`, D4, D15) |
| The question | `ConfirmDialog.titleKey`, `explanationKey`, `confirmKey`, `cancelKey` | Names the file and the project, and says what loading does in the manager's name |
| What was loaded | `messageKeyOf('projects.loadFileDone')`, `messageKeyOf('projects.loadFileDoneNoReport')` | The bar: how many entries in how many tables, and the report, from the API's own answer; for a file with no report, the word that names none (D9) |
| Another refusal | `messageKeyOf('projects.loadFile.<code>')` | The bar: not a project file, a newer one, a project holding entries |

`ProjectFileRefusalsScreen` at `/projects/:projectId/project-file/refused`, opened when rows are refused:

| Element | `Key` | Does |
| --- | --- | --- |
| Nothing was saved | `ProjectFileRefusalsScreen.headingKey` | The line over the list, in the refusal color |
| A refusal | `ProjectFileRefusalsScreen.refusalKey(index)` | Its title is where it is, the file's item, table and «#» with the row's place; its subtitle why, in its owner's own word (D14) |

## API calls

| Call | When |
| --- | --- |
| `POST /projects/{projectId}/project-file` | Loading: the file, sent as every file is, so it waits the file timeout (UC-070) |
| `GET /projects` | After the answer, so the button grays once the project holds its entries (`holdsEntries`, D15) |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| AC-53.2, D1: without «إدارة المشروع» the button is gray, never hidden | `Project.mayLoadFile`, `ProjectSettingsCard` | `project_file_loading_test.dart`: AC-53.2, D1; Patrol `project_file_test.dart`: AC-53.2; `buttons_test.dart`: redix-api #132, AC-53.2 |
| AC-53.3, D4, D15: once the API says the project holds an entry, the button is gray | `Project.holdsEntries`, `Project.mayLoadFile` | `project_file_loading_test.dart`: AC-53.3, D4, D15 |
| FR-53: the question names the file and the project, and going back sends nothing | `loadProjectFile` | `project_file_loading_test.dart`: FR-53: the picked file is named in the question |
| FR-53, AC-53.1: once loaded the bar says what the API loaded, and the button turns gray | `loadProjectFile`, `Projects.loadFile`, `Projects.lastLoad` | `project_file_loading_test.dart`: FR-53, AC-53.1; Patrol `project_file_test.dart`: AC-53.1 |
| AC-53.5, D14: every refused row is listed by its item, table and row, each in its owner's word, and nothing changes | `ProjectFileRefusalsScreen`, `ProjectFileRefusal`, `ProjectFileOwner` | `project_file_loading_test.dart`: AC-53.5, D14; Patrol `project_file_test.dart`: AC-53.5 |
| D9: a file that carries no report is loaded with a bar that names no report | `loadProjectFile` | `project_file_loading_test.dart`: D9: a file that carries no report |
| AC-29.3: a report the project issued already is listed with its number | `ProjectFileRefusal.reasonIn` | `project_file_loading_test.dart`: AC-29.3: a report the project issued already |
| AC-53.9: a file that is not a project file says so in the bar | `loadProjectFile` | `project_file_loading_test.dart`: AC-53.9; Patrol `project_file_test.dart`: AC-53.9 |
| Picking nothing asks nothing and sends nothing | `loadProjectFile`, `InvoiceCapture.fromProjectFiles` | `project_file_loading_test.dart`: a person who picks nothing |
