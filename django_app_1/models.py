import pytz
import json

from django.db import models
from django.utils import timezone

from phonenumber_field.modelfields import PhoneNumberField


class Reservation(models.Model):
    first_name = models.CharField(max_length=20, null=False, blank=False)
    last_name = models.CharField(max_length=20, null=False, blank=False)
    phone = PhoneNumberField(null=False, blank=False)
    email = models.CharField(max_length=100, null=False, blank=False)
    check_in = models.DateTimeField(null=False, blank=False)
    check_out = models.DateTimeField(null=False, blank=False)
    created_at = models.DateTimeField(auto_now_add=True, null=False, blank=False)
    updated_at = models.DateTimeField(auto_now=True, null=False, blank=False)
    notes = models.TextField(max_length=400)
    time_format = "%Y-%m-%d %H:%M"

    def __str__(self):
        timezone_name = timezone.get_current_timezone()
        return f"{self.first_name} {self.last_name}, {self.phone}, {self.email}, " + \
            f"F:{self.check_in.strftime(self.time_format)}, " + \
            f"T:{self.check_out.strftime(self.time_format)}, " + \
            f"U:{self.updated_at.strftime(self.time_format)}, {timezone_name}, {self.notes}"

    def to_dict(self):
        dict_object = {
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": self.email,
            "phone": self.phone,
            "check_in": self.check_in.strftime(self.time_format),
            "check_out": self.check_out.strftime(self.time_format),
            "created_at": self.created_at.strftime(self.time_format),
            "updated_at": self.updated_at.strftime(self.time_format),
            "notes": self.notes
        }
        return dict_object

    def to_json(self):
        dict_object = {
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": self.email,
            "phone": self.phone,
            "check_in": self.check_in.strftime(self.time_format),
            "check_out": self.check_out.strftime(self.time_format),
            "created_at": self.created_at.strftime(self.time_format),
            "updated_at": self.updated_at.strftime(self.time_format),
            "notes": self.notes
        }
        return json.dumps(dict_object)


