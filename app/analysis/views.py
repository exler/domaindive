from django.views.generic import FormView

from analysis.forms import RequestAnalysisForm


class RequestAnalysisView(FormView):
    template_name = "analysis/request_analysis.html"
    form_class = RequestAnalysisForm
