$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-test-' + [guid]::NewGuid().ToString('N'))
$oldSkip=$env:DOTFILES_SKIP_PACKAGES
$env:DOTFILES_SKIP_PACKAGES='1'
try {
    $terminalDir="$temporary/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
    New-Item -ItemType Directory -Path "$temporary/Documents/PowerShell","$temporary/AppData/Roaming/Cursor/User",$terminalDir -Force | Out-Null
    '# preserved local PowerShell config' | Set-Content "$temporary/Documents/PowerShell/profile.ps1"
    '{"window.zoomLevel": 2, "terminal.integrated.fontFamily": "MartianMono NFM", "terminal.integrated.defaultProfile.windows": "Fish", "terminal.integrated.profiles.windows": {"Fish": {"path": "wsl.exe", "args": ["--exec", "fish", "-l"]}, "Ubuntu": {"path": "wsl.exe"}}}' | Set-Content "$temporary/AppData/Roaming/Cursor/User/settings.json"
    '{"defaultProfile": "{00000000-0000-0000-0000-00000000f1f1}", "profiles": {"defaults": {"font": {"face": "MartianMono NFM", "size": 13}}, "list": [{"guid": "{00000000-0000-0000-0000-00000000f1f1}", "name": "Ubuntu Fish", "commandline": "wsl.exe -d Ubuntu-24.04 --cd ~ --exec fish -l"}, {"guid": "{00000000-0000-0000-0000-0000000ab5c1}", "name": "Ubuntu", "commandline": "wsl.exe -d Ubuntu-24.04"}]}}' | Set-Content "$terminalDir/settings.json"
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
    if ($cursor.'window.zoomLevel' -ne 2 -or $cursor.'terminal.integrated.fontFamily' -or $cursor.'editor.fontFamily' -match 'MartianMono' -or $cursor.'git.path') { throw 'Cursor portability/font cleanup failed.' }
    if ($cursor.'terminal.integrated.profiles.windows'.Fish -or -not $cursor.'terminal.integrated.profiles.windows'.Ubuntu -or $cursor.'terminal.integrated.defaultProfile.windows' -ne 'PowerShell') { throw 'Cursor fish profile cleanup failed.' }
    $terminal=Get-Content "$terminalDir/settings.json" -Raw | ConvertFrom-Json
    if ($terminal.profiles.defaults.font) { throw 'Terminal font cleanup failed.' }
    if (@($terminal.profiles.list | Where-Object { $_.commandline -match 'fish' }).Count -or -not @($terminal.profiles.list | Where-Object { $_.name -eq 'Ubuntu' }).Count -or $terminal.defaultProfile -ne '{a15d747b-e8ee-4c3a-b914-e6fed15e410a}') { throw 'Terminal fish profile cleanup failed.' }
    if (-not (Test-Path "$temporary/AppData/Local/nvim/init.lua")) { throw 'Neovim configuration missing.' }
    foreach ($excluded in @('.bashrc','.config/fish','.config/sh','Library','tests','.github')) {
        if (Test-Path (Join-Path $temporary $excluded)) { throw "Unix/internal target leaked to Windows: $excluded" }
    }
    Write-Output 'PASS: Windows rendering, repeat apply, profile preservation, JSON configuration, font/fish cleanup and OS exclusions'
} finally {
    $env:DOTFILES_SKIP_PACKAGES=$oldSkip
    $resolved=[IO.Path]::GetFullPath($temporary)
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
