#!/bin/bash -x

echo "Setup variables"

DB_USER=dbuser
DB_PASS=django
DB_NAME=djangodb

read -p "Enter valid path to git repository: " repo
PROJECT_REPOSITORY=${repo}
DJANGO_PROJECT=`basename ${PROJECT_REPOSITORY}`

IP=`curl http://checkip.amazonaws.com`

export DJANGO_SUPERUSER_USERNAME=admin
export DJANGO_SUPERUSER_PASSWORD=admin
export DJANGO_SUPERUSER_EMAIL=admin@mail.com

DEBUG=false
askContinue() {
    if [ "${DEBUG}" == "true" ];
    then
        read -p "Next step [yes|no]? " next
        if [ "$next" != "yes" ];
        then 
            exit
        fi
    fi
}

echo "Step 0: Update and install packages"
sudo apt update
sudo apt -y install git net-tools python3-pip python3-dev python3-venv libpq-dev postgresql postgresql-contrib nginx curl

askContinue

echo "Step 1: Create database and user $DB_USER to access postgres"
sudo -u postgres psql<<EOF
CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';
CREATE DATABASE ${DB_NAME} WITH OWNER=${DB_USER};
ALTER ROLE ${DB_USER} SET client_encoding TO 'utf8';
ALTER ROLE ${DB_USER} SET default_transaction_isolation TO 'read committed';
ALTER ROLE ${DB_USER} SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF

askContinue

echo "Step 2: Clone project from git"
cd ${HOME}
echo "Clean old project"
rm -r ${DJANGO_PROJECT}
git clone ${PROJECT_REPOSITORY}

askContinue

echo "Step 3: Create and activate virtual environment, install requered packages, migrate database"
cd ${DJANGO_PROJECT}
python3 -m venv venv
. ./venv/bin/activate
pip install -r requirements.txt
python manage.py makemigrations
python manage.py migrate
sudo chmod a+w /var/www/html
python manage.py collectstatic
python manage.py createsuperuser --noinput
cd ${HOME}

askContinue

echo "Step 4: Setup gunicorn"
# pip install gunicorn
# gunicorn -w 3 --bind 0.0.0.0:8000 djangoproject.wsgi
cat<<EOF >> gunicorn.socket
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
EOF
sudo cp -f ./gunicorn.socket  /etc/systemd/system/gunicorn.socket
rm ./gunicorn.socket
cat<<EOF >> gunicorn.service
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=${USER}
Group=www-data
WorkingDirectory=${HOME}/${DJANGO_PROJECT}
ExecStart=${HOME}/${DJANGO_PROJECT}/venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn.sock \
          ${DJANGO_PROJECT}.wsgi:application

[Install]
WantedBy=multi-user.target
EOF
sudo cp -f ./gunicorn.service /etc/systemd/system/gunicorn.service
rm ./gunicorn.service
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
sudo systemctl status gunicorn.socket

echo "Check gunicorn"
file /run/gunicorn.sock
sudo journalctl -u gunicorn.socket
sudo systemctl status gunicorn
curl --unix-socket /run/gunicorn.sock localhost
sudo systemctl status gunicorn

askContinue

echo "Step 5: Setup nginx"

sudo cat<<EOF >> myproject
server {
    listen 80;
    server_name ${IP};

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root /var/www/html;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
EOF
sudo cp -f ./myproject  /etc/nginx/sites-available/myproject
rm ./myproject
sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

echo "All done"