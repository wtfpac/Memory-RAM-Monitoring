$totalAllocation = 10GB  # Total memoria a ser alocada
$blockSize = 256MB      # Tamanho de cada bloco
$pauseBetweenBlocks = 1 # segundos entre alocações

# lista de referencias de memoria
$memoryBlocks = New-Object System.Collections.Generic.List[object]

try {
    # calcular qtde blocos necessarios
    $blocksCount = [math]::Ceiling($totalAllocation / $blockSize)
    
    Write-Host "Alocando $($totalAllocation/1GB) GB em blocos de $($blockSize/1MB) MB..."
    Write-Host "Aguarde alguns minutos.." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $blocksCount; $i++) {
        # Aloca o bloco de memória e preenche com dados
        $block = [byte[]]::new($blockSize)
        
        # Preenche o bloco com dados para forçar alocação física
        for ($j = 0; $j -lt $blockSize; $j += 4096) {
            $block[$j] = 1
        }
        
        $memoryBlocks.Add($block)
        $allocated = $i * $blockSize
        
        # progresso
        Write-Progress -Activity "Alocando memória" -Status "$($allocated/1GB) GB de $($totalAllocation/1GB) GB" -PercentComplete ($allocated/$totalAllocation*100)
        Write-Host "Alocado: $($allocated/1GB) GB" -ForegroundColor Green
        
        Start-Sleep -Seconds $pauseBetweenBlocks
    }

    Write-Host "`n[SUCESSO] $($totalAllocation/1GB) GB alocados com sucesso" -ForegroundColor Green
    Write-Host "Pressione Enter para parar e liberar a memória" -ForegroundColor White
    Read-Host
}
finally {
    # Libera a memória
    $memoryBlocks.Clear()
    [GC]::Collect()
    Write-Host "Memória liberada." -ForegroundColor Green
}