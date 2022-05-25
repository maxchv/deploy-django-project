sudo chown -R www-data:www-data /home/ubuntu/djangoproject/static/
sudo cp -f nginx.config  /etc/nginx/sites-available/myproject
sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

