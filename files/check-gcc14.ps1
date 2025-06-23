function Get-MingwPathFromGcc {
    $gccCmd = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gccCmd) {
        $gccPath = $gccCmd.Source
        # Get the parent directory (bin)
        $binDir = Split-Path $gccPath -Parent
        return $binDir
    }
    return $null
}

$gcc = Get-Command gcc -ErrorAction SilentlyContinue

$isGcc14 = $false
$version = $null

if ($gcc) {
    $versionLine = & gcc --version | Select-Object -First 1
    if ($versionLine -match '(\d+\.\d+\.\d+)') {
        $version = $matches[1]
        $major = $version.Split('.')[0]
        if ([int]$major -ge 14) {
            $isGcc14 = $true
        }
    }
}

$mingwNewPath = "C:\MinGW14\bin"

if ($isGcc14) {
    Write-Host "`nGCC 14 or newer is ready to use! Version: $version"
} else {
    if ($version) {
        Write-Host "`nGCC version $version is NOT 14 or newer. Removing old MinGW path and adding MinGW14 to PATH...`n"
        $oldMingwPath = Get-MingwPathFromGcc
    } else {
        Write-Host "`nGCC 14 or newer is NOT available. Adding MinGW14 to PATH...`n"
        $oldMingwPath = $null
    }
    # Remove old MinGW path if present
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $pathParts = $currentPath -split ';'
    if ($oldMingwPath) {
        $pathParts = $pathParts | Where-Object { $_ -and ($_ -ne $oldMingwPath) }
    }
    # Add new MinGW14 path if not already present
    if (-not ($pathParts -contains $mingwNewPath)) {
        $pathParts += $mingwNewPath
    }
    $newPath = ($pathParts -join ';').Trim(';')
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
    Write-Host "Please restart your terminal or log out and back in for changes to take effect."
}