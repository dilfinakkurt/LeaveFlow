chcp 65001
$env:PATH = "C:\Ruby33-x64\bin;C:\Ruby33-x64\bin\ruby_builtin_dlls;$env:PATH"
Write-Host "LeaveFlow Başlatılıyor: http://localhost:3000" -ForegroundColor Green
ruby -E UTF-8:UTF-8 bin/rails server -u webrick
