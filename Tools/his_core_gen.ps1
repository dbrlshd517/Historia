# his_core_gen.ps1 - HistoriaCore Gen folder (headless core compiled by UBT; link_mode must be "source").
# Called by Tools\his_core_gen.bat (Historia.uproject PreBuildSteps, before UBT scans sources).
# One generated .cpp/.c per source: a single #include of the original file (no source copy).
# File list = headless CMakeLists add_library(<name> STATIC ...) for historia_corelib, historia_setting,
# historia_tools, historia_bakelib + external sources pinned in deps_dir (ThirdParty/HisDeps: miniz, yyjson; stb is header only).
# Pin check (deps_dir/VERSIONS.json): headless CMakeLists FetchContent GIT_TAG == git_tag, file sha256 == files,
# and every FetchContent lib of the compiled CMakeLists is pinned. Any mismatch -> exit code 1.
# A Gen file is rewritten only if its content changed (keeps timestamps -> no needless recompiles).
# ASCII only on purpose: Windows PowerShell 5.1 reads BOM-less .ps1 as the ANSI code page.
$ErrorActionPreference = 'Stop'
try {
    $proj = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $cfg = [IO.File]::ReadAllText((Join-Path $proj 'Config\HisCore.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
    $gen = Join-Path $proj 'Source\HistoriaCore\Private\Gen'
    if ($cfg.link_mode -ne 'source') { throw "Config/HisCore.json link_mode = '$($cfg.link_mode)': only 'source' is supported (prebuilt was removed)" }

    # headless dir: env HISTORIA_HEADLESS > headless_dir ({sub} = project folder name after 'Historia')
    $dir = $cfg.headless_dir
    if ($env:HISTORIA_HEADLESS) { $dir = $env:HISTORIA_HEADLESS }
    $name = Split-Path $proj -Leaf
    $sub = if ($name.StartsWith('Historia')) { $name.Substring(8) } else { '' }
    $dir = $dir.Replace('{sub}', $sub)
    if (-not [IO.Path]::IsPathRooted($dir)) { $dir = Join-Path $proj $dir }
    $hl = [IO.Path]::GetFullPath($dir)
    if (-not (Test-Path (Join-Path $hl 'playheadless\core.hpp'))) { throw "headless_dir is not historia-headless: $hl" }

    # --- external sources pin check ---
    $deps = [IO.Path]::GetFullPath((Join-Path $proj $cfg.deps_dir))
    $verPath = Join-Path $deps 'VERSIONS.json'
    if (-not (Test-Path $verPath)) { throw "missing $verPath" }
    $ver = [IO.File]::ReadAllText($verPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $pinned = @{}
    foreach ($p in $ver.libs.PSObject.Properties) {
        $lib = $p.Name; $v = $p.Value
        $pinned[$lib] = $true
        $cm = [IO.File]::ReadAllText((Join-Path $hl $v.cmake), [Text.Encoding]::UTF8)
        $m = [regex]::Match($cm, 'FetchContent_Declare\(\s*' + [regex]::Escape($lib) + '\s[^)]*?GIT_TAG\s+([^\s)]+)')
        if (-not $m.Success) { throw "headless $($v.cmake) has no FetchContent_Declare($lib ... GIT_TAG ...) - pinned lib '$lib' no longer used? update $verPath" }
        $tag = $m.Groups[1].Value
        if ($tag -ne $v.git_tag) { throw "$lib version mismatch: headless $($v.cmake) GIT_TAG '$tag' != VERSIONS.json git_tag '$($v.git_tag)' - update ThirdParty/HisDeps/$lib (Docs/STATUS.md pin bump)" }
        foreach ($f in $v.files.PSObject.Properties) {
            $fp = Join-Path $deps (Join-Path $lib $f.Name)
            if (-not (Test-Path $fp)) { throw "pinned file missing: $fp" }
            $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $fp).Hash.ToLowerInvariant()
            if ($h -ne $f.Value.ToLowerInvariant()) { throw "sha256 mismatch: $fp is $h, VERSIONS.json says $($f.Value)" }
        }
    }
    # every FetchContent lib of the CMakeLists we compile from must be pinned (a new lib, e.g. Recast, needs Build.cs + HisDeps work)
    foreach ($cmf in 'playheadless\CMakeLists.txt', 'Startsetting\CMakeLists.txt') {
        $cm = [IO.File]::ReadAllText((Join-Path $hl $cmf), [Text.Encoding]::UTF8)
        foreach ($m in [regex]::Matches($cm, '(?m)^[^#\r\n]*FetchContent_Declare\(\s*([A-Za-z0-9_]+)')) {
            $lib = $m.Groups[1].Value
            if (-not $pinned.ContainsKey($lib)) { throw "headless $cmf declares external lib '$lib' that is not pinned in $verPath (add it to ThirdParty/HisDeps + HistoriaCore.Build.cs)" }
        }
    }

    # --- Gen file list ---
    $files = New-Object System.Collections.Generic.List[string]
    function Get-CMakeSources([string]$sub, [string]$lib) {
        $d = Join-Path $hl $sub
        $text = [IO.File]::ReadAllText((Join-Path $d 'CMakeLists.txt'), [Text.Encoding]::UTF8)
        $m = [regex]::Match($text, 'add_library\(\s*' + [regex]::Escape($lib) + '\s+STATIC([^)]*)\)')
        if (-not $m.Success) { throw "$sub/CMakeLists.txt has no add_library($lib STATIC ...)" }
        $out = @()
        foreach ($line in $m.Groups[1].Value -split "`n") {
            $t = ($line -split '#')[0].Trim()
            if ($t.EndsWith('.cpp') -or $t.EndsWith('.c')) { $out += [IO.Path]::GetFullPath((Join-Path $d $t)) }
        }
        return $out
    }
    foreach ($f in (Get-CMakeSources 'playheadless' 'historia_corelib')) { $files.Add($f) }
    foreach ($lib in 'historia_setting', 'historia_tools', 'historia_bakelib') {
        foreach ($f in (Get-CMakeSources 'Startsetting' $lib)) { $files.Add($f) }
    }
    foreach ($f in 'miniz.c', 'miniz_tdef.c', 'miniz_tinfl.c', 'miniz_zip.c') { $files.Add((Join-Path $deps "miniz\$f")) }
    $files.Add((Join-Path $deps 'yyjson\yyjson.c'))
    foreach ($f in $files) { if (-not (Test-Path $f)) { throw "source missing: $f" } }
    if (-not (Test-Path $gen)) { New-Item -ItemType Directory -Path $gen | Out-Null }

    $utf8 = New-Object Text.UTF8Encoding $false
    $keep = @{}
    $written = 0
    foreach ($f in $files) {
        $d1 = Split-Path $f -Parent
        $rel = (Split-Path (Split-Path $d1 -Parent) -Leaf) + '_' + (Split-Path $d1 -Leaf) + '_' + [IO.Path]::GetFileNameWithoutExtension($f)
        $ext = if ($f.EndsWith('.c')) { '.c' } else { '.cpp' }
        $out = Join-Path $gen ('his_' + $rel + $ext)
        $body = "// generated by Tools/his_core_gen.ps1 - do not edit. Compiles the original as is.`n#include `"" + $f.Replace('\', '/') + "`"`n"
        $keep[$out.ToLowerInvariant()] = $true
        if (-not (Test-Path $out) -or [IO.File]::ReadAllText($out, $utf8) -ne $body) {
            [IO.File]::WriteAllText($out, $body, $utf8)
            $written++
        }
    }
    $removed = 0
    foreach ($old in Get-ChildItem $gen -File) {
        if (-not $keep.ContainsKey($old.FullName.ToLowerInvariant())) { Remove-Item $old.FullName; $removed++ }
    }
    Write-Output ("[his_core_gen] pins ok ({0}) - {1} files, {2} written, {3} removed -> {4}" -f (($pinned.Keys | Sort-Object) -join ','), $files.Count, $written, $removed, $gen)
    exit 0
}
catch {
    Write-Output "[his_core_gen] error: $($_.Exception.Message)"
    exit 1
}
