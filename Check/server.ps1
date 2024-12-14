$port = 12345

$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)

$listener.Start()
Write-Host "The TCP server has started and is listening on port $port..."

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        Write-Host "client has connected:$($client.Client.RemoteEndPoint)"

        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        $data = $reader.ReadLine()
        Write-Host "recived data:$data"

        $response = "234,DXGNC-PWV89-WHH88-8C9HK-RM47F"
        $writer.WriteLine($response)

        $writer.Close()
        $reader.Close()
        $client.Close()
    }
}
catch {
    Write-Host "error：$_"
}
finally {
    $listener.Stop()
    Write-Host "TCP server has stop."
}