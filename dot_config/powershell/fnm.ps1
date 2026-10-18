# fnm uses junctions on Windows. Some installations can enumerate the installed
# versions but cannot resolve aliases/current through those junctions. Preserve
# native behavior, with a fallback to the same target Windows exposes to PowerShell.
$script:DotfilesFnm = (Get-Command fnm -CommandType Application -ErrorAction Stop).Source
function Get-DotfilesNodeVersion([string]$Link) {
    $item = Get-Item -LiteralPath $Link -ErrorAction SilentlyContinue
    $target = @($item.Target)[0]
    if ($target -and (Test-Path -LiteralPath (Join-Path $target 'node.exe'))) {
        return Split-Path (Split-Path $target -Parent) -Leaf
    }
}
function global:fnm {
    $arguments = @($args)
    if ($arguments.Count -eq 1 -and $arguments[0] -eq 'current') {
        $current = & $script:DotfilesFnm current
        if ($current -eq 'none' -and $env:FNM_MULTISHELL_PATH) {
            $fallback = Get-DotfilesNodeVersion $env:FNM_MULTISHELL_PATH
            if ($fallback) { $current = $fallback }
        }
        $current
        return
    }
    if ($arguments.Count -eq 1 -and $arguments[0] -eq 'default' -and $env:FNM_DIR) {
        $fallback = Get-DotfilesNodeVersion (Join-Path $env:FNM_DIR 'aliases/default')
        if ($fallback) { $fallback; $global:LASTEXITCODE=0; return }
    }
    if ($arguments.Count -gt 1 -and $arguments[0] -eq 'use' -and $env:FNM_DIR) {
        for ($index=1; $index -lt $arguments.Count; $index++) {
            if ($arguments[$index] -match '^[a-zA-Z][a-zA-Z0-9-]*$') {
                $fallback = Get-DotfilesNodeVersion (Join-Path $env:FNM_DIR ('aliases/' + $arguments[$index]))
                if ($fallback) { $arguments[$index]=$fallback }
            }
        }
    }
    & $script:DotfilesFnm @arguments
    $result=$LASTEXITCODE
    if ($result -eq 0 -and $arguments.Count -gt 0 -and $arguments[0] -in @('use','install')) {
        $selected = Get-Item -LiteralPath $env:FNM_MULTISHELL_PATH -ErrorAction SilentlyContinue
        $target = @($selected.Target)[0]
        if ($target -and (Test-Path -LiteralPath (Join-Path $target 'node.exe'))) {
            $parts = @($env:Path.Split(';') | Where-Object { $_ -ne $script:DotfilesNodePath -and $_ -ne $target })
            $script:DotfilesNodePath=$target
            $env:Path=$target + ';' + ($parts -join ';')
        }
    }
    $global:LASTEXITCODE=$result
}
