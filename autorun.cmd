@echo off
:: This was not working, something is wrong with the spaces
:: python "%~dp0run.py" >> "d:\Logs\PlannerMeetingNotes-%date:~10,4%%date:~7,2%%date:~4,2%.log" 2>>&1

:: This works
python "%~dp0run.py" >> "d:\Logs\PlannerMeetingNotes.log" 2>>&1