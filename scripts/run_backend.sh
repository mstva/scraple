#!/bin/bash

VENV_DIR=.venv

if [ ! -d $VENV_DIR ]; then
    python3.11 -m venv $VENV_DIR
    . $VENV_DIR/bin/activate
    pip install --upgrade pip
    pip install poetry
    poetry config virtualenvs.create false
fi

. $VENV_DIR/bin/activate
set -e
cd backend
poetry install --no-interaction --no-ansi
python manage.py collectstatic --noinput
python manage.py makemigrations --noinput
python manage.py migrate --noinput
python manage.py runserver 0.0.0.0:8001
