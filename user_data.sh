#!/bin/bash
set -e

exec > >(tee -a /var/log/user-data-deployment.log) 2>&1

echo "Starting portfolio deployment..."

apt-get update -y
apt-get install -y nginx git

systemctl enable --now nginx

if [ -d /opt/portfolio/.git ]; then
    git -C /opt/portfolio pull
else
    rm -rf /opt/portfolio
    git clone https://github.com/rahulmoganati/port.git /opt/portfolio
fi

rm -rf /var/www/html/*
cp -r /opt/portfolio/. /var/www/html/

chown -R www-data:www-data /var/www/html
systemctl restart nginx

echo "Portfolio deployment completed."
