# Copyright 2026 Tech Details. All rights reserved.
# Use of this file is governed by the LICENSE file at the root of this repository.

# How much of the app the widget tests run: every line of lib, the generated word getters left out, as a report in coverage/report/index.html and a
# summary printed here. Flutter measures (flutter test --coverage); ReportGenerator, from the repo's tool manifest, reads its lcov file. Flutter measures only
# the files a test loads, so for the measurement alone a test loading every file of lib is written and then deleted: a file no test opens counts at 0%
# instead of being left out of the report.
$root = Split-Path $PSScriptRoot
Set-Location $root
Remove-Item coverage -Recurse -Force -ErrorAction SilentlyContinue
$every = Join-Path $root 'test\every_file_coverage_test.dart'
$imports = Get-ChildItem lib -Recurse -Filter *.dart | Where-Object { -not (Select-String -Path $_.FullName -Pattern '^part of ' -Quiet) } | ForEach-Object -Begin { $n = 0 } -Process {
  $n++
  "import 'package:redix/$((Resolve-Path -Relative $_.FullName -RelativeBasePath (Join-Path $root 'lib')).Substring(2).Replace('\', '/'))' as file$n;"
}
Set-Content -Path $every -Encoding utf8 -Value (@('// Written by tool/coverage.ps1 for one measurement, then deleted: it loads every file of lib.') + $imports + @('', 'void main() {}'))
try {
  flutter test --coverage 2>&1 | Select-Object -Last 1
} finally {
  Remove-Item $every -Force
}
dotnet tool restore | Out-Null
dotnet tool run reportgenerator "-reports:coverage/lcov.info" "-sourcedirs:$root" "-targetdir:coverage/report" "-reporttypes:Html;TextSummary" "-title:REDIX app" "-filefilters:-*.g.dart" | Out-Null
Get-Content coverage/report/Summary.txt | Select-Object -First 16
