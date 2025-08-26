from django import forms


class RequestAnalysisForm(forms.Form):
    # Domain name or IP address
    address = forms.CharField(widget=forms.TextInput(attrs={"placeholder": "example.com or 192.0.2.1"}))
