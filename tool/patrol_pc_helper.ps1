# What a Patrol case on the phone cannot do for itself. The Patrol run starts this on the PC, and a case asks it over port 5011 (patrol_test/support/pc.dart).
param([Parameter(Mandatory)][string]$Device)
# The app Patrol runs: always dev (redix-app #95). Its activity keeps the code's own package, sa.redix.
$App = 'sa.redix.dev'

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 5011)
$listener.Start()
while ($true) {
  $client = $listener.AcceptTcpClient()
  $stream = $client.GetStream()
  $reader = [System.IO.StreamReader]::new($stream)
  $path, $query = ($reader.ReadLine() -split ' ')[1] -split '\?', 2
  while ($reader.ReadLine()) { }
  $answer = '200 OK'
  switch ($path) {
    '/network/off' { adb -s $Device reverse --remove tcp:5010 2>&1 | Out-Null }
    '/network/on' { adb -s $Device reverse tcp:5010 tcp:5010 2>&1 | Out-Null }
    '/link' { adb -s $Device shell am start -a android.intent.action.VIEW -d ([uri]::UnescapeDataString($query)) $App 2>&1 | Out-Null }
    '/to-downloads' {
      $name = [uri]::UnescapeDataString($query)
      adb -s $Device shell cp "/sdcard/Android/data/$App/files/$name" "/sdcard/Download/$name" 2>&1 | Out-Null
      adb -s $Device shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Download/$name" 2>&1 | Out-Null
    }
    '/share-in' {
      $type, $file = [uri]::UnescapeDataString($query) -split '\|', 2
      adb -s $Device shell am start -a android.intent.action.SEND -t $type --eu android.intent.extra.STREAM "file://$file" -n "$App/sa.redix.MainActivity" 2>&1 | Out-Null
    }
    '/notepad/close' { adb -s $Device shell am force-stop com.huawei.notepad 2>&1 | Out-Null }
    '/downloaded' {
      $start = [uri]::UnescapeDataString($query)
      $found = @(adb -s $Device shell "find /sdcard/Download -maxdepth 1 -name '$start*' -mmin -2" 2>&1 | Where-Object { "$_" -like '/sdcard/*' })
      if ($found.Count -eq 0) { $answer = '404 Not Found' }
      foreach ($file in $found) {
        adb -s $Device shell "rm '$file'" 2>&1 | Out-Null
        adb -s $Device shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$($file -replace ' ', '%20')" 2>&1 | Out-Null
      }
    }
    '/note' { Add-Content -Path 'C:\Users\mtb\REDIX\.night\patrol-results.log' -Value ([uri]::UnescapeDataString($query)) -Encoding UTF8 }
    default { $answer = '404 Not Found' }
  }
  $bytes = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 $answer`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
  $stream.Write($bytes, 0, $bytes.Length)
  $client.Close()
}
