from django.urls import path

from analysis.views import RequestAnalysisView

urlpatterns = [
    path("", RequestAnalysisView.as_view(), name="request_analysis"),
]
