#!/bin/bash

echo "Step 0: Update and install packages"
sudo apt -y update
sudo apt -y install python3-pip python3-dev python3-venv libpq-dev postgresql postgresql-contrib nginx curl

echo "Step 1: Create database and user to access postgres"
sudo -u postgres psql<<EOF
CREATE USER dbuser WITH ENCRYPTED PASSWORD 'django';
CREATE DATABASE djangodb WITH OWNER=dbuser;
ALTER ROLE dbuser SET client_encoding TO 'utf8';
ALTER ROLE dbuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE dbuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE djangodb TO dbuser;
EOF

echo "Step 2: Create venv install django and create project, migrate database"
mkdir djangoproject
cd djangoproject
python3 -m venv venv
. venv/bin/activate
pip install django psycopg2-binary
django-admin startproject djangoproject .
cp -f ./configs/settings.py djangoproject
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic
export DJANGO_SUPERUSER_USERNAME=admin
export DJANGO_SUPERUSER_PASSWORD=admin
export DJANGO_SUPERUSER_EMAIL=admin@mail.com
python manage.py createsuperuser --noinput

echo "Step 3: Setup gunicorn"
pip install gunicorn
# gunicorn -w 3 --bind 0.0.0.0:8000 djangoproject.wsgi
sudo cp -f ./configs/gunicorn.socket  /etc/systemd/system/gunicorn.socket
sudo cp -f ./configs/gunicorn.service /etc/systemd/system/gunicorn.service
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
sudo systemctl status gunicorn.socket

echo "Check gunicorn"
file /run/gunicorn.sock
sudo journalctl -u gunicorn.socket
sudo systemctl status gunicorn
curl --unix-socket /run/gunicorn.sock localhost
sudo systemctl status gunicorn

echo "Step 4: Setup nginx"
sudo cp -f ./configs/myproject  /etc/nginx/sites-available/myproject
sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

echo "All done"