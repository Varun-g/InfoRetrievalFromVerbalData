from django import forms
from django.forms import ModelForm
# from .models import user

class UploadFileForm(forms.Form):
    title = forms.CharField(max_length=50)
    file = forms.FileField()
    
# class UserForm(ModelForm):
# 	password = forms.CharField(widget=forms.PasswordInput)

# 	class Meta:
# 		model = User
# 		fields = '__all__'
