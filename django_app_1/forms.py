from datetime import datetime
from django.forms import ModelForm
from django.forms import CharField
from django.forms import EmailInput
from django.forms import DateTimeInput
from django.forms import Textarea
from django.forms import TextInput
from django.utils.translation import gettext_lazy as _

from bootstrap_datepicker_plus import DateTimePickerInput
from phonenumber_field.widgets import PhoneNumberInternationalFallbackWidget

from .models import Reservation


class ReservationForm(ModelForm):
    required_css_class = "required"

    def __init__(self, *args, **kwargs):
        super(ReservationForm, self).__init__(*args, **kwargs)
        for field_name, field in self.fields.items():
            if field_name == "notes":
                field.required = False
            else:
                field.required = True

    class Meta:
        model = Reservation
        exclude = ["created_at", "updated_at"]
        labels = {
            "first_name": _("First Name"),
            "last_name": _("Last Name"),
            "check_in": _("Check In"),
            "check_out": _("Check Out"),
        }
        error_messages = {
            "phone": {
                "invalid": "Valid format: \"xxx-xxx-xxxx\" or \"(xxx) xxx-xxxx\" or \"+\" an international region code"
            }
        }
        widgets = {
            "first_name": TextInput(attrs={
                "placeholder": f"{Reservation._meta.get_field('first_name').max_length} Characters Max",
                "class": "form-control"
            }),
            "last_name": TextInput(attrs={
                "placeholder": f"{Reservation._meta.get_field('last_name').max_length} Characters Max",
                "class": "form-control"
            }),
            "phone": PhoneNumberInternationalFallbackWidget(attrs={"placeholder": "xxx-xxx-xxxx", "class": "form-control"}),
            "email": EmailInput(attrs={"placeholder": "abc@xyz.com", "class": "form-control"}),
            "check_in": DateTimePickerInput(
                attrs={"placeholder": "YYYY-MM-DD HH:mm", "class": "form-control"},
                options={"showClose": True, "showClear": True, "showTodayButton": True, "format": "YYYY-MM-DD HH:mm"}
            ),
            "check_out": DateTimePickerInput(
                attrs={"placeholder": "YYYY-MM-DD HH:mm", "class": "form-control"},
                options={"showClose": True, "showClear": True, "showTodayButton": True, "format": "YYYY-MM-DD HH:mm"}
            ),
            "notes": Textarea(attrs={
                "placeholder": f"(Optional) {Reservation._meta.get_field('notes').max_length} Characters Max",
                "class": "form-control"
            })
        }

    def clean(self):
        cleaned_data = super().clean()
        cleaned_check_in_time = cleaned_data.get("check_in")
        cleaned_check_out_time = cleaned_data.get("check_out")
        if cleaned_check_in_time >  cleaned_check_out_time:
            error_msg = "\"Check In\" must be earlier than \"Check Out\""
            self.add_error("check_in", error_msg)
            self.add_error("check_out", error_msg)
