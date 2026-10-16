@echo off
rem Abre la interfaz grafica (pide permisos de administrador)
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0OptiXeo-GUI.ps1"
