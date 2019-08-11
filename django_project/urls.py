from django.contrib import admin
from django.urls import path
from django.urls import include


urlpatterns = [
    # http://localhost:8000/ 
    path(route="django_app_1/", view=include("django_app_1.urls")),
    path(route="django_app_1/admin/", view=admin.site.urls)
]
