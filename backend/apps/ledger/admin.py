import re

from django import forms
from django.contrib import admin

from .models import (
    AuditLog,
    Client,
    Contract,
    Landlord,
    LandlordClientRelation,
    Notification,
    Party,
    PartyType,
    Transaction,
)


USERNAME_PATTERN = re.compile(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{10}$')


class PartyAdminForm(forms.ModelForm):
    class Meta:
        model = Party
        fields = '__all__'

    def clean_username(self):
        username = (self.cleaned_data.get('username') or '').strip()
        party_type = self.cleaned_data.get('party_type')

        if party_type in {PartyType.CLIENT, PartyType.LANDLORD}:
            if not USERNAME_PATTERN.match(username):
                raise forms.ValidationError(
                    'Landlord and client usernames must be exactly 10 characters '
                    'and include at least one uppercase letter, one lowercase letter, '
                    'and one number.',
                )
        return username


class LandlordClientRelationInlineForLandlord(admin.TabularInline):
    model = LandlordClientRelation
    fk_name = 'landlord'
    extra = 0
    autocomplete_fields = ('client',)
    fields = ('client', 'created_at')
    readonly_fields = ('created_at',)


class LandlordClientRelationInlineForClient(admin.TabularInline):
    model = LandlordClientRelation
    fk_name = 'client'
    extra = 0
    autocomplete_fields = ('landlord',)
    fields = ('landlord', 'created_at')
    readonly_fields = ('created_at',)


@admin.register(Party)
class PartyAdmin(admin.ModelAdmin):
    form = PartyAdminForm
    list_display = ('name', 'username', 'party_type', 'government_identifier')
    list_filter = ('party_type',)
    search_fields = ('name', 'username', 'government_identifier')
    fields = ('name', 'username', 'party_type', 'government_identifier')

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.base_fields['username'].help_text = (
            'For landlord and client records, use exactly 10 characters with at least '
            'one uppercase letter, one lowercase letter, and one number. '
            'Example: Abc123XyZ9'
        )
        return form


class RolePartyAdmin(admin.ModelAdmin):
    form = PartyAdminForm
    list_display = ('name', 'username', 'government_identifier')
    search_fields = ('name', 'username', 'government_identifier')

    forced_party_type = None

    def get_queryset(self, request):
        return super().get_queryset(request).filter(party_type=self.forced_party_type)

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        if 'party_type' in form.base_fields:
            form.base_fields['party_type'].initial = self.forced_party_type
            form.base_fields['party_type'].widget = forms.HiddenInput()
        form.base_fields['username'].help_text = (
            'Use exactly 10 characters with at least one uppercase letter, '
            'one lowercase letter, and one number. Example: Abc123XyZ9'
        )
        return form

    def save_model(self, request, obj, form, change):
        obj.party_type = self.forced_party_type
        super().save_model(request, obj, form, change)


@admin.register(Landlord)
class LandlordAdmin(RolePartyAdmin):
    forced_party_type = PartyType.LANDLORD
    fields = ('name', 'username', 'government_identifier', 'party_type')
    inlines = (LandlordClientRelationInlineForLandlord,)


@admin.register(Client)
class ClientAdmin(RolePartyAdmin):
    forced_party_type = PartyType.CLIENT
    fields = ('name', 'username', 'government_identifier', 'party_type')
    inlines = (LandlordClientRelationInlineForClient,)


@admin.register(LandlordClientRelation)
class LandlordClientRelationAdmin(admin.ModelAdmin):
    list_display = ('landlord', 'client', 'created_at')
    search_fields = (
        'landlord__name',
        'landlord__username',
        'client__name',
        'client__username',
    )
    autocomplete_fields = ('landlord', 'client')
    readonly_fields = ('created_at',)


class TransactionInline(admin.TabularInline):
    model = Transaction
    extra = 0
    fields = (
        'transaction_type',
        'charge_label',
        'status',
        'amount',
        'payer',
        'payee',
        'payment_channel',
        'payment_reference',
        'occurred_at',
    )
    ordering = ('-occurred_at',)


@admin.register(Contract)
class ContractAdmin(admin.ModelAdmin):
    list_display = (
        'code',
        'landlord',
        'client',
        'municipality',
        'start_date',
        'end_date',
        'base_rent',
        'annual_increment_percent',
        'status',
    )
    list_filter = ('municipality', 'start_date', 'end_date')
    search_fields = (
        'code',
        'landlord__name',
        'landlord__username',
        'client__name',
        'client__username',
        'municipality__name',
    )
    autocomplete_fields = ('landlord', 'client', 'municipality')
    inlines = (TransactionInline,)


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        'contract',
        'transaction_type',
        'charge_label',
        'status',
        'amount',
        'payer',
        'payee',
        'payment_channel',
        'occurred_at',
    )
    list_filter = ('transaction_type', 'status', 'payment_channel')
    search_fields = (
        'contract__code',
        'payment_reference',
        'charge_label',
        'payer__name',
        'payee__name',
    )
    autocomplete_fields = ('contract', 'payer', 'payee')
    ordering = ('-occurred_at',)


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('action', 'actor', 'transaction', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('action', 'actor__name', 'transaction__contract__code')
    autocomplete_fields = ('actor', 'transaction')
    ordering = ('-created_at',)


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('title', 'recipient', 'notification_type', 'is_read', 'created_at')
    list_filter = ('notification_type', 'is_read', 'created_at')
    search_fields = ('title', 'message', 'recipient__name', 'recipient__username')
    autocomplete_fields = ('recipient', 'contract', 'transaction')
    ordering = ('-created_at',)
