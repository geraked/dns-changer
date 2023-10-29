@echo off
title Build
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -Command ^"^
Invoke-ps2exe dns.ps1 -x86 -requireAdmin -noConsole ^
-iconFile 'icon.ico' ^
-title 'DNS Changer' ^
-product 'DNS Changer' ^
-version '1.0.0' ^
-company 'Geraked' ^
-copyright '2023 Geraked' ^"

pause