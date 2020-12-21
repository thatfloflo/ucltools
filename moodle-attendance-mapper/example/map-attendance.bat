@echo off
ECHO Mapping moodle attendance...
ECHO.
Rscript moodle-attendance-mapper.r
ECHO.
ECHO Press any key to exit...
PAUSE > NUL
