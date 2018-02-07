@echo off
title 8-puzzle Game Compiler
color 02
goto Compiler

:Compiler
  set runGame=N
  fpc puzzle8uas.pas
  echo Compiled successfully!
  set /p runGame=Run the game? (Y/[N]) : 
  if /I "%runGame%"=="y" (
    puzzle8uas.exe
    exit /B
  ) else (
    color 1f
    echo Exiting. Press any key to continue . . .
    pause>nul
    exit /B
  )
  