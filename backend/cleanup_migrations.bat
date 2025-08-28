@echo off
ECHO --- DELETING MIGRATION FILES ---

REM Loop through all subdirectories
FOR /d /r . %%d IN (migrations) DO (
    IF EXIST "%%d" (
        REM Delete all .py files in the migrations folder, except __init__.py
        FOR %%f IN ("%%d\*.py") DO (
            IF /I NOT "%%~nxf" == "__init__.py" (
                ECHO Deleting %%f
                del "%%f"
            )
        )
        REM Delete all .pyc files
        IF EXIST "%%d\*.pyc" (
            ECHO Deleting %%d\*.pyc
            del "%%d\*.pyc"
        )
    )
)
ECHO Migration files deleted.
ECHO.

ECHO --- DELETING SQLITE DATABASE ---
IF EXIST db.sqlite3 (
    del db.sqlite3
    ECHO db.sqlite3 deleted.
) ELSE (
    ECHO db.sqlite3 not found, skipping.
)
ECHO.

ECHO --- CLEANUP COMPLETE ---
ECHO You can now run 'python manage.py makemigrations' and 'python manage.py migrate'.