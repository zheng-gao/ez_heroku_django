import pytz

from django.contrib import admin
from django.utils import timezone

from rangefilter.filter import DateRangeFilter, DateTimeRangeFilter

from .models import Reservation
from .apps import APP_DISPLAY_NAME


# Page Title
admin.site.site_header = f"{APP_DISPLAY_NAME} Administration"
admin.site.site_title = f"{APP_DISPLAY_NAME} Admin Portal"
admin.site.index_title = "" # f"Welcome to {APP_DISPLAY_NAME} Admin Portal"
admin.site.site_url = "/django_app_1"


def convert_to_django_time_string(utctime):
    utc = utctime.replace(tzinfo=pytz.UTC)
    # timezone.get_default_timezone() = TIME_ZONE defined in project/settings.py
    # which is the timezone of server running django apps
    # e.g. If your django app deployed to a server in Japan, then TIME_ZONE = "Asia/Tokyo"
    localtz = utc.astimezone(timezone.get_default_timezone())
    return localtz.strftime("%F %H:%M")  # YYYY-MM-DD HH:mm


def limit_string_size(input_string, size=30):
    dots = "..."
    cut_size = int(size) - len(dots)
    if cut_size > 0:
        if len(input_string) > int(size):
            return input_string[:cut_size] + dots
        else:
            return input_string
    else:
        raise Exception(f"Cannot limit string size to {size}")


class ReservationAdmin(admin.ModelAdmin):
    class Media:
        js = ("js/admin/admin_search_bar.js", )

    list_display = (
        "first_name", "last_name", "phone", "email",
        "format_check_in", "format_check_out", "format_updated_at", "format_notes"
    )
    search_fields = ("first_name", "last_name", "phone", "email")
    list_filter = (
        ("check_in", DateTimeRangeFilter),
        ("check_out", DateTimeRangeFilter),
        ("updated_at", DateTimeRangeFilter),
    )

    def format_check_in(self, obj):
        return convert_to_django_time_string(obj.check_in)
    format_check_in.admin_order_field = "check_in"
    format_check_in.short_description = "Check In"

    def format_check_out(self, obj):
        return convert_to_django_time_string(obj.check_out)
    format_check_out.admin_order_field = "check_out"
    format_check_out.short_description = "Check Out"

    def format_updated_at(self, obj):
        return convert_to_django_time_string(obj.updated_at)
    format_updated_at.admin_order_field = "updated_at"
    format_updated_at.short_description = "Updated At"

    def format_notes(self, obj):
        return limit_string_size(obj.notes)
    format_notes.admin_order_field = "notes"
    format_notes.short_description = "Notes"

    # Remove the action default string "------------"
    def get_action_choices(self, request):
        # choices is a list, just change it, the first is the BLANK_CHOICE_DASH
        choices = super(ReservationAdmin, self).get_action_choices(request)
        choices.pop(0)
        return choices

    # # Replace the action default string "------------" with other string
    # def get_action_choices(self, request):
    #     default_choices = [("", "Please select an action")]
    #     return super(ReservationAdmin, self).get_action_choices(request, default_choices)

admin.site.register(Reservation, ReservationAdmin)
