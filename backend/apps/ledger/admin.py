from django.contrib import admin

from .models import AuditLog, Contract, Party, Transaction

admin.site.register(Party)
admin.site.register(Contract)
admin.site.register(Transaction)
admin.site.register(AuditLog)
