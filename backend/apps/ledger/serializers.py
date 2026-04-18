from rest_framework import serializers

from .models import AuditLog, Contract, Party, Transaction


class PartySerializer(serializers.ModelSerializer):
    class Meta:
        model = Party
        fields = ['id', 'name', 'party_type', 'government_identifier']


class ContractSerializer(serializers.ModelSerializer):
    landlord = PartySerializer(read_only=True)
    client = PartySerializer(read_only=True)
    municipality = PartySerializer(read_only=True)

    class Meta:
        model = Contract
        fields = [
            'id',
            'code',
            'landlord',
            'client',
            'municipality',
            'start_date',
            'end_date',
            'base_rent',
            'annual_increment_percent',
            'created_at',
            'updated_at',
        ]


class AuditLogSerializer(serializers.ModelSerializer):
    actor = PartySerializer(read_only=True)

    class Meta:
        model = AuditLog
        fields = ['id', 'transaction', 'actor', 'action', 'metadata', 'created_at']


class TransactionSerializer(serializers.ModelSerializer):
    payer = PartySerializer(read_only=True)
    payee = PartySerializer(read_only=True)
    audit_logs = AuditLogSerializer(many=True, read_only=True)

    class Meta:
        model = Transaction
        fields = [
            'id',
            'contract',
            'transaction_type',
            'status',
            'amount',
            'payer',
            'payee',
            'payment_channel',
            'payment_reference',
            'occurred_at',
            'created_at',
            'audit_logs',
        ]
