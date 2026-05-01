from rest_framework import serializers

from .models import AuditLog, Contract, Notification, Party, Transaction


class PartySerializer(serializers.ModelSerializer):
    class Meta:
        model = Party
        fields = [
            'id',
            'name',
            'username',
            'party_type',
            'government_identifier',
        ]


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
            'recurring_charges',
            'optional_terms',
            'status',
            'approved_at',
            'created_at',
            'updated_at',
        ]


class ContractCreateSerializer(serializers.Serializer):
    client_id = serializers.IntegerField()
    municipality_id = serializers.IntegerField(required=False)
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    base_rent = serializers.DecimalField(max_digits=12, decimal_places=2)
    annual_increment_percent = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
    )
    recurring_charges = serializers.ListField(
        child=serializers.DictField(),
        allow_empty=False,
    )
    optional_terms = serializers.ListField(
        child=serializers.CharField(),
        required=False,
    )

    def validate_client_id(self, value):
        client = Party.objects.filter(id=value, party_type='client').first()
        if not client:
            raise serializers.ValidationError('Client user id is invalid.')
        return value

    def validate(self, attrs):
        if attrs['end_date'] <= attrs['start_date']:
            raise serializers.ValidationError(
                {'end_date': 'End date must be after start date.'},
            )

        recurring_charges = attrs.get('recurring_charges', [])
        normalized_charges = []
        for item in recurring_charges:
            label = str(item.get('label', '')).strip()
            amount = item.get('amount')
            is_auto_increment = bool(item.get('is_auto_increment', False))
            if not label:
                raise serializers.ValidationError(
                    {'recurring_charges': 'Each charge requires a label.'},
                )
            try:
                parsed_amount = float(amount)
            except (TypeError, ValueError):
                raise serializers.ValidationError(
                    {'recurring_charges': f'Charge "{label}" has an invalid amount.'},
                )
            if parsed_amount < 0:
                raise serializers.ValidationError(
                    {'recurring_charges': f'Charge "{label}" must be zero or more.'},
                )
            normalized_charges.append(
                {
                    'label': label,
                    'amount': parsed_amount,
                    'is_auto_increment': is_auto_increment,
                }
            )

        attrs['recurring_charges'] = normalized_charges
        attrs['optional_terms'] = [
            str(item).strip()
            for item in attrs.get('optional_terms', [])
            if str(item).strip()
        ]
        return attrs


class PaymentCreateSerializer(serializers.Serializer):
    contract_id = serializers.IntegerField()
    charge_label = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError('Amount must be greater than zero.')
        return value


class AuditLogSerializer(serializers.ModelSerializer):
    actor = PartySerializer(read_only=True)

    class Meta:
        model = AuditLog
        fields = [
            'id',
            'transaction',
            'actor',
            'action',
            'metadata',
            'created_at',
        ]


class TransactionSerializer(serializers.ModelSerializer):
    payer = PartySerializer(read_only=True)
    payee = PartySerializer(read_only=True)
    claimed_by = PartySerializer(read_only=True)
    approved_by = PartySerializer(read_only=True)
    audit_logs = AuditLogSerializer(many=True, read_only=True)
    can_claim = serializers.SerializerMethodField()
    can_approve = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = [
            'id',
            'contract',
            'transaction_type',
            'charge_label',
            'status',
            'amount',
            'payer',
            'payee',
            'payment_channel',
            'payment_reference',
            'occurred_at',
            'claimed_by',
            'approved_by',
            'claimed_at',
            'approved_at',
            'created_at',
            'audit_logs',
            'can_claim',
            'can_approve',
        ]

    def get_can_claim(self, obj):
        party = self.context.get('party')
        return bool(
            party
            and party.party_type == 'client'
            and obj.status == 'pending'
            and obj.contract.client_id == party.id
        )

    def get_can_approve(self, obj):
        party = self.context.get('party')
        return bool(
            party
            and party.party_type == 'landlord'
            and obj.status == 'claimed'
            and obj.contract.landlord_id == party.id
        )


class NotificationSerializer(serializers.ModelSerializer):
    contract_code = serializers.CharField(source='contract.code', read_only=True)
    transaction_reference = serializers.CharField(
        source='transaction.payment_reference',
        read_only=True,
    )

    class Meta:
        model = Notification
        fields = [
            'id',
            'title',
            'message',
            'notification_type',
            'contract',
            'contract_code',
            'transaction',
            'transaction_reference',
            'is_read',
            'created_at',
        ]


class UserOverviewSerializer(serializers.Serializer):
    user = PartySerializer()
    contracts = ContractSerializer(many=True)
    transactions = TransactionSerializer(many=True)
    notifications = NotificationSerializer(many=True)
