# Monitoramento de memória
$refreshInterval = 1  # atualizaçao a cada 1s

$previousMemoryUsage = 0
$previousTime = [DateTime]::Now

function Get-MemoryUsage {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedGB = $totalGB - $freeGB
    $percentUsed = [math]::Round(($usedGB / $totalGB) * 100)
    
    return @{
        TotalGB = $totalGB
        UsedGB = $usedGB
        FreeGB = $freeGB
        PercentUsed = $percentUsed
    }
}

function Get-MemoryThroughput {
    param (
        $currentUsage,
        $previousUsage,
        $timeSpan
    )
    
    if ($timeSpan.TotalSeconds -eq 0) { return 0 } # nao dividir por 0
    $deltaUsage = $currentUsage - $previousUsage
    return [math]::Round($deltaUsage / $timeSpan.TotalSeconds, 2)  # MB/s
}

function Get-CPUUsage {
    $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue).LoadPercentage
    if ($null -eq $cpu) { return 0 } else { return $cpu }
}

try {
    Write-Host "`n🖥️  MONITOR DE MEMÓRIA`n"
    Write-Host "Tempo   Uso(GB)   Livre(GB)  Uso(%)  CPU(%)  Throughput(MB/s)  [Total: $((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB)GB]"
    Write-Host "------  --------   ---------  ------  ------  ----------------"
    
    $startTime = Get-Date
    $previousMemoryUsage = (Get-MemoryUsage).UsedGB * 1024  # Converter GB para MB > throughput
    
    while ($true) {
        $currentTime = [DateTime]::Now
        $timeSpan = $currentTime - $previousTime
        $memory = Get-MemoryUsage
        $currentUsageMB = $memory.UsedGB * 1024  # Converter para MB
        $throughput = Get-MemoryThroughput -currentUsage $currentUsageMB -previousUsage $previousMemoryUsage -timeSpan $timeSpan
        $cpu = Get-CPUUsage
        $elapsed = $currentTime - $startTime
        
        # vermelho = alocando memória, verde = liberando memória 
        $throughputColor = if ($throughput -gt 0) { 'Red' } elseif ($throughput -lt 0) { 'Green' } else { 'Gray' }
        $throughputText = if ($throughput -gt 0) { "+$throughput" } else { "$throughput" }
        
        Write-Host ("{0,-6}  {1,-8:N2}  {2,-9:N2}  {3,-6}  {4,-5}  " -f `
            ("{0:mm\:ss}" -f $elapsed),
            $memory.UsedGB,
            $memory.FreeGB,
            $memory.PercentUsed,
            $cpu) -NoNewline
            
        Write-Host $throughputText -ForegroundColor $throughputColor

        # Atualiza valores p proximo calculo
        $previousMemoryUsage = $currentUsageMB
        $previousTime = $currentTime
        
        Start-Sleep -Seconds $refreshInterval
    }
}
finally {
    $totalTime = (Get-Date) - $startTime
    $timeString = "{0:mm\:ss}" -f $totalTime
    Write-Host "`n⏱️  Monitoramento encerrado. Tempo total: $timeString" -ForegroundColor Cyan
}