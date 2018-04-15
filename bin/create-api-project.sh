#! /bin/bash

set -euo pipefail

# Grab environment variables
. ./.env

# Remove sample files and database
echo "Removing the sample project..."
bin/remove-sample.sh

# Create django project and api app
echo "Removing 'db_development' and 'aoi' images"
docker rmi db_development:latest api:latest

echo "Creating new Django Rest Framework Project Scaffold..."
echo "This will take some time"
docker-compose -f development-docker-compose.yml run api_development \
  /bin/bash -c "django-admin.py startproject $PROJECT_NAME . ; python manage.py startapp api"

echo "Saving database restore log"
container_id=`docker ps | grep db_development | sed 's; .*$;;'`
docker logs $container_id > db_development.log

echo "Removing temporary containers..."
docker-compose -f development-docker-compose.yml down

# fix ownership
echo "Fixing ownership on Linux"
if [ `uname -s` = "Linux" ]
then
  ls -l
  echo "sudo chown -R `id -u $USER`:`id -g $USER` ."
  sudo chown -R `id -u $USER`:`id -g $USER` .
  ls -l
fi

# Replace newly created settings with the example settings
echo "Configuring settings..."
rm $PROJECT_NAME/settings.py
cp ./bin/example-settings.py $PROJECT_NAME/settings.py
sed -i "s;\<EXAMPLE_PROJECT_NAME\>;$PROJECT_NAME;g" $PROJECT_NAME/settings.py

echo "Finished"
