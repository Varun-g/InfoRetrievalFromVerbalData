from __future__ import unicode_literals

from django.db import models

# Create your models here.

class User(models.Model):
   firstname = models.CharField(max_length=50)
   lastname = models.CharField(max_length=50)
   email = models.CharField(max_length=50,primary_key=True)
   password = models.CharField(max_length=100)

   def __unicode__(self):
    	return self.email