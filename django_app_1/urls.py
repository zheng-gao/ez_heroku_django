from django.urls import path

from . import views


urlpatterns = [
    path(route="", view=views.index, name="index"),
    path(route="index.html", view=views.index, name="index"),
    path(route="contact.html", view=views.contact, name="contact"),
    path(route="reservation.html", view=views.reservation, name="reservation"),
]
