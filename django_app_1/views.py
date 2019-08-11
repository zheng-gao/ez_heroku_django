# import json

from django.http import HttpResponse
from django.http import JsonResponse
from django.shortcuts import render

from .models import Reservation
from .forms import ReservationForm


def index(request):
    return render(request, "index.html")


def contact(request):
    return render(request, "contact.html")


def reservation(request):
    if request.method == "POST":
        render(request, "reservation/confirmation.html")
        form = ReservationForm(request.POST)
        if form.is_valid():
            first_name = form.cleaned_data["first_name"]
            last_name = form.cleaned_data["last_name"]
            phone = form.cleaned_data["phone"]
            email = form.cleaned_data["email"]
            check_in = form.cleaned_data["check_in"]
            check_out = form.cleaned_data["check_out"]
            notes = form.cleaned_data["notes"]
            print(f"first_name: {first_name}")
            print(f"last_name: {last_name}")
            print(f"phone: {phone}")
            print(f"email: {email}")
            print(f"check_in: {check_in}")
            print(f"check_out: {check_out}")
            print(f"notes: {notes}")
            reservation_record = form.save()
            if reservation_record:
                print("Saved")
                return render(request, "reservation/confirmation.html")
            else:
                print("Failed to save reservation")
    else:
        form = ReservationForm()
    return render(request, "reservation/reservation.html", {"form": form})
