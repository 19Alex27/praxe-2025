# Start-DemoAdmin.ps1 — откроет новое окно PowerShell АДМИНОМ и зайдёт в папку demo
$targetDir = "C:\Users\19gee\praxe-2025\demo"
$cmd = "Set-Location `"$targetDir`""
Start-Process PowerShell -Verb RunAs -ArgumentList "-NoExit","-Command",$cmd
