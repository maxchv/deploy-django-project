# Easy deploy django project on AWS EC2

To install basic django project with postgresql, nginx and gunicorn you should simple run the script `setup.sh`.

```bash
$ git clone https://github.com/maxchv/deploy-django-project
$ cd deploy-django-project
$ . setup.sh
$ Enter valid path to git repository: https://github.com/maxchv/DemoDjangoProject
```

![Screen record installation](screen/install.gif)

## Django admin

By default superuser has username `admin` and password `admin`

## Database config

By default database has user `dbuser` with password `django` and he has own database `djangodb`. 