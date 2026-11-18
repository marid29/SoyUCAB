@echo off
echo Iniciando servidor PHP...
echo.
echo El servidor estara disponible en: http://localhost:8000
echo.
echo Presiona Ctrl+C para detener el servidor
echo.
cd /d "%~dp0"
"C:\Program Files\XAMPP\php\php.exe" -S localhost:8000

