#!/bin/bash

set -e

#-----------------------------
# Install required packages
#-----------------------------

sudo apt update -y

sudo apt install -y wget build-essential libncursesw5-dev libssl-dev \
libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev

sudo add-apt-repository -y ppa:deadsnakes/ppa

sudo apt install -y python3.11 python3.11-venv

sudo apt install -y postgresql postgresql-contrib

sudo apt install -y nginx

#-----------------------------
# Setup and create the postgres database
#-----------------------------

DB_PASSWORD=$(printf "%s\n" "'$POSTGRES_PASSWORD'")

sudo -u postgres -i <<EOF
psql -c "CREATE DATABASE $POSTGRES_DB"
psql -c "CREATE USER $POSTGRES_USER WITH PASSWORD $DB_PASSWORD"
psql -c "ALTER ROLE $POSTGRES_USER SET client_encoding TO 'utf8'"
psql -c "ALTER ROLE $POSTGRES_USER SET default_transaction_isolation TO 'read committed'"
psql -c "ALTER ROLE $POSTGRES_USER SET timezone TO 'UTC'"
psql -c "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER"
EOF

#-----------------------------
# Setup Django Project
#-----------------------------

PROJECT_DIR=nginx-gcp-django
VENV_DIR=.venv

if [ ! -d $PROJECT_DIR ]; then
    sudo git clone https://github.com/mstva/$PROJECT_DIR.git $PROJECT_DIR
fi

cd $PROJECT_DIR
sudo git pull

if [ ! -d $VENV_DIR ]; then
    python3.11 -m venv $VENV_DIR
    chmod 744 -R $VENV_DIR/*
    . $VENV_DIR/bin/activate
    pip install --upgrade pip
    pip install poetry
    poetry config virtualenvs.create false
fi

. $VENV_DIR/bin/activate
cd backend
poetry install --no-interaction --no-ansi
python manage.py collectstatic --noinput
python manage.py makemigrations --noinput
python manage.py migrate --noinput

#-----------------------------
# Setup Nginx
#-----------------------------

if [ -f /etc/systemd/system/gunicorn.socket ]; then
    sudo rm /etc/systemd/system/gunicorn.socket
fi

echo "
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
" | sudo tee -a /etc/systemd/system/gunicorn.socket

sudo systemctl daemon-reload

if [ -f /etc/systemd/system/gunicorn.service ]; then
    sudo rm /etc/systemd/system/gunicorn.service
fi

echo "
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=/home/$USER/$PROJECT_DIR/backend
ExecStart=/home/$USER/$PROJECT_DIR/$VENV_DIR/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          src.wsgi:application

[Install]
WantedBy=multi-user.target
" | sudo tee -a /etc/systemd/system/gunicorn.service

sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket

file /run/gunicorn.sock

sudo systemctl daemon-reload
sudo systemctl restart gunicorn

if [ -f /etc/nginx/sites-available/$PROJECT_DIR ]; then
    sudo rm /etc/nginx/sites-available/$PROJECT_DIR
    sudo rm /etc/nginx/sites-enabled/$PROJECT_DIR
fi

echo "
server {
    listen 80;
    server_name 34.168.75.58;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /home/$USER/$PROJECT_DIR/backend;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
" | sudo tee -a /etc/nginx/sites-available/$PROJECT_DIR

sudo ln -s /etc/nginx/sites-available/$PROJECT_DIR /etc/nginx/sites-enabled

sudo nginx -t

sudo systemctl restart nginx

sudo ufw delete allow 8000
sudo ufw allow 'Nginx Full'

