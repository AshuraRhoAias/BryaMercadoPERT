@echo off
REM Doble clic para correr las 5 pruebas de verificacion sin escribir nada
REM en la terminal. Internamente solo llama a ejecutar_todo.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ejecutar_todo.ps1"
echo.
pause
