# 定义服务器端口
$port = 12345

# 创建 TCP 侦听器
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)

# 启动侦听器
$listener.Start()
Write-Host "The TCP server has started and is listening on port $port..."

try {
    while ($true) {
        # 接受客户端连接
        $client = $listener.AcceptTcpClient()
        Write-Host "client has connected:$($client.Client.RemoteEndPoint)"

        # 获取网络流
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true

        # 读取客户端发送的数据
        $data = $reader.ReadLine()
        Write-Host "recived data:$data"

        # 发送响应数据
        $response = "234,DXGNC-PWV89-WHH88-8C9HK-RM47F"
        $writer.WriteLine($response)

        # 关闭连接
        $writer.Close()
        $reader.Close()
        $client.Close()
    }
}
catch {
    Write-Host "error：$_"
}
finally {
    # 停止侦听器
    $listener.Stop()
    Write-Host "TCP server has stop."
}