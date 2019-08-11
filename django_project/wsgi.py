import os

from django.core.wsgi import get_wsgi_application
from .settings import django_project_name

os.environ.setdefault("DJANGO_SETTINGS_MODULE", f"{django_project_name}.settings")

application = get_wsgi_application()
