@echo off
chcp 65001 > nul
set "PATH=C:\Ruby33-x64\bin;C:\Ruby33-x64\bin\ruby_builtin_dlls;%PATH%"
echo LeaveFlow Baslatiliyor (http://localhost:3000)...
ruby -E UTF-8:UTF-8 bin\rails server -u webrick
pause
