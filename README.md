# Easy deploy django project on AWS EC2

To install basic django project with postgresql, nginx and gunicorn you should simple run the script `setup.sh`.

```bash
$ git clone [https://github.com/maxchv/deploy-django-project](https://github.com/maxchv/deploy-django-project)
$ cd deploy-django-project
$ . setup.sh
$ Enter valid path to git repository: [https://github.com/maxchv/DemoDjangoProject](https://github.com/maxchv/DemoDjangoProject)
```

![Screen record installation](screen/install.gif)

## Django admin

By default superuser has username `admin` and password `admin`

## Database config

By default database has user `dbuser` with password `django` and he has own database `djangodb`.

## Requirements for django project

Your project should has the file requirements.txt with all requirements.

You need to set `STATIC_ROOT` contstan in `settings.py` to `'/var/www/html/static'`:

```python
STATIC_ROOT = '/var/www/html/static'
```

Also you need to setup database configuration for postgres:

```python
DATABASES= {
    'default' : {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'djangodb',
        'USER': 'dbuser',
        'PASSWORD': 'django',
        'HOST': 'localhost',
        'PORT': ''
    }
}
```

And constant `ALLOWED_HOSTS` set to allow access from any hosts:

```python
ALLOWED_HOSTS = ['*']
```

It is very important to turn of debug mode:

```python
DEBUG = False
```