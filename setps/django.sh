mkdir djangoproject
cd djangoproject
python3 -m venv venv
. venv/bin/activate
pip install django psycopg2-binary gunicorn
django-admin startproject djangoproject .
cp -f ../configs/settings.py djangoproject
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic
export DJANGO_SUPERUSER_USERNAME=admin
export DJANGO_SUPERUSER_PASSWORD=admin
export DJANGO_SUPERUSER_EMAIL=admin@mail.com
python manage.py createsuperuser --noinput
# gunicorn -w 3 --bind 0.0.0.0:8000 djangoproject.wsgi
