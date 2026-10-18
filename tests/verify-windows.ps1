$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-test-' + [guid]::NewGuid().ToString('N'))
$oldSkip=$env:DOTFILES_SKIP_PACKAGES
$env:DOTFILES_SKIP_PACKAGES='1'
try {
    New-Item -ItemType Directory -Path "$temporary/Documents/PowerShell","$temporary/AppData/Roaming/Cursor/User" -Force | Out-Null
    '# preserved local PowerShell config' | Set-Content "$temporary/Documents/PowerShell/profile.ps1"
    '{"window.zoomLevel": 2}' | Set-Content "$temporary/AppData/Roaming/Cursor/User/settings.json"
    $config=Join-Path $temporary 'chezmoi.toml'
    & chezmoi init --apply --force --no-tty --source $repo --destination $temporary --config $config
    if ($LASTEXITCODE -ne 0) { throw 'First apply failed.' }
    & chezmoi apply --force --no-tty --source $repo --destination $temporary --config $config
    if ($LASTEXITCODE -ne 0) { throw 'Repeat apply failed.' }
    foreach ($file in (Get-ChildItem "$temporary/.config/powershell" -Filter '*.ps1')) {
        $parseErrors=$null
        [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$null,[ref]$parseErrors) | Out-Null
        if ($parseErrors) { throw ($parseErrors | Out-String) }
    }
    $profile=Get-Content "$temporary/Documents/PowerShell/profile.ps1" -Raw
    if ($profile -notmatch '# preserved local PowerShell config' -or ([regex]::Matches($profile,'# >>> dotfiles powershell >>>')).Count -ne 1) { throw 'Profile preservation/idempotence failed.' }
    $cursor=Get-Content "$temporary/AppData/Roaming/Cursor/User/settings.json" -Raw | ConvertFrom-Json
    if ($cursor.'window.zoomLevel' -ne 2 -or $cursor.'terminal.integrated.fontFamily' -ne 'MartianMono NFM' -or $cursor.'git.path') { throw 'Cursor portability failed.' }
    $terminal=Get-Content "$temporary/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" -Raw | ConvertFrom-Json
    if ($terminal.profiles.defaults.font.face -ne 'MartianMono NFM') { throw 'Terminal font selection failed.' }
    if (-not (Test-Path "$temporary/AppData/Local/nvim/init.lua")) { throw 'Neovim configuration missing.' }
    foreach ($excluded in @('.bashrc','.config/fish','.config/sh','Library','tests','.github')) {
        if (Test-Path (Join-Path $temporary $excluded)) { throw "Unix/internal target leaked to Windows: $excluded" }
    }
    Write-Output 'PASS: Windows rendering, repeat apply, profile preservation, JSON configuration and OS exclusions'
} finally {
    $env:DOTFILES_SKIP_PACKAGES=$oldSkip
    $resolved=[IO.Path]::GetFullPath($temporary)
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
