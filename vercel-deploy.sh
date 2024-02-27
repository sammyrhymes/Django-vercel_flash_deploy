#!/bin/bash

# Check if a directory path is provided
if [ -z "$1" ]; then
    echo "Please provide the path to the Django project directory."
    exit 1
fi

# Navigate to the Django project directory
cd "$1" || exit 1

# Create build_files.sh
echo 'pip install psycopg2-binary' > build_files.sh
echo 'python manage.py collectstatic' >> build_files.sh
chmod +x build_files.sh

# Create vercel.json
echo '{
  "version": 2,
  "builds": [
    {
      "src": "projectname/wsgi.py",
      "use": "@vercel/python",
      "config": { "maxLambdaSize": "15mb", "runtime": "python3.9" }
    },
    {
      "src": "build_files.sh",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "staticfiles_build"
      }
    }
  ],
  "routes": [
    {
      "src": "/static/(.*)",
      "dest": "/static/$1"
    },
    {
      "src": "/(.*)",
      "dest": "projectname/wsgi.py"
    }
  ]
}' > vercel.json

# Configure static files in settings.py
echo -e "\nSTATIC_URL = '/static/'" >> projectname/settings.py
echo "STATIC_ROOT = os.path.join(BASE_DIR, 'static')" >> projectname/settings.py

# Configure urlpatterns in urls.py
echo -e "\nfrom django.conf import settings" >> projectname/urls.py
echo "from django.conf.urls.static import static" >> projectname/urls.py
echo -e "\nurlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)" >> projectname/urls.py

# Make migrations and migrate database
python manage.py makemigrations
python manage.py migrate

# Add allowed hosts to settings.py
echo -e "\nALLOWED_HOSTS = ['localhost', '127.0.0.1', '.now.sh', '.vercel.app']" >> projectname/settings.py

# Install psycopg2-binary and generate requirements.txt
pip install psycopg2-binary
pip freeze > requirements.txt

echo "Setup complete for $1!"
