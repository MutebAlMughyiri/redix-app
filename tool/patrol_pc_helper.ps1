# What a Patrol case on the phone cannot do for itself. The Patrol run starts this on the PC, and a case asks it over port 5011 (patrol_test/support/pc.dart).
param([Parameter(Mandatory)][string]$Device)

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 5011)
$listener.Start()
while ($true) {
  $client = $listener.AcceptTcpClient()
  $stream = $client.GetStream()
  $reader = [System.IO.StreamReader]::new($stream)
  $path = ($reader.ReadLine() -split ' ')[1]
  while ($reader.ReadLine()) { }
  $answer = '200 OK'
  switch ($path) {
    '/network/off' { adb -s $Device reverse --remove tcp:5010 2>&1 | Out-Null }
    '/network/on' { adb -s $Device reverse tcp:5010 tcp:5010 2>&1 | Out-Null }
    default { $answer = '404 Not Found' }
  }
  $bytes = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 $answer`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
  $stream.Write($bytes, 0, $bytes.Length)
  $client.Close()
}
