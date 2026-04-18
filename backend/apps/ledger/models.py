from django.db import models


class PartyType(models.TextChoices):
    LANDLORD = 'landlord', 'Landlord'
    CLIENT = 'client', 'Client'
    MUNICIPALITY = 'municipality', 'Municipality'


class PaymentChannel(models.TextChoices):
    FONEPAY = 'fonepay', 'Fonepay'
    WALLET = 'wallet', 'Wallet'
    BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'


class TransactionType(models.TextChoices):
    RENT = 'rent', 'Rent'
    ELECTRICITY = 'electricity', 'Electricity'
    WATER = 'water', 'Water'
    WASTE = 'waste_management', 'Waste Management'


class TransactionStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    COMPLETED = 'completed', 'Completed'
    FAILED = 'failed', 'Failed'
    DISPUTED = 'disputed', 'Disputed'


class Party(models.Model):
    name = models.CharField(max_length=255)
    party_type = models.CharField(max_length=32, choices=PartyType.choices)
    government_identifier = models.CharField(max_length=64, blank=True)

    def __str__(self) -> str:
        return f'{self.name} ({self.party_type})'


class Contract(models.Model):
    code = models.CharField(max_length=64, unique=True)
    landlord = models.ForeignKey(Party, on_delete=models.PROTECT, related_name='landlord_contracts')
    client = models.ForeignKey(Party, on_delete=models.PROTECT, related_name='client_contracts')
    municipality = models.ForeignKey(Party, on_delete=models.PROTECT, related_name='municipality_contracts')
    start_date = models.DateField()
    end_date = models.DateField()
    base_rent = models.DecimalField(max_digits=12, decimal_places=2)
    annual_increment_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return self.code


class Transaction(models.Model):
    contract = models.ForeignKey(Contract, on_delete=models.PROTECT, related_name='transactions')
    transaction_type = models.CharField(max_length=32, choices=TransactionType.choices)
    status = models.CharField(max_length=32, choices=TransactionStatus.choices, default=TransactionStatus.PENDING)
    amount = models.DecimalField(max_digits=12, decimal_places=2)

    payer = models.ForeignKey(Party, on_delete=models.PROTECT, related_name='payments_made')
    payee = models.ForeignKey(Party, on_delete=models.PROTECT, related_name='payments_received')

    payment_channel = models.CharField(max_length=32, choices=PaymentChannel.choices)
    payment_reference = models.CharField(max_length=128)
    occurred_at = models.DateTimeField()

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-occurred_at']


class AuditLog(models.Model):
    transaction = models.ForeignKey(Transaction, on_delete=models.PROTECT, related_name='audit_logs', null=True, blank=True)
    actor = models.ForeignKey(Party, on_delete=models.PROTECT)
    action = models.CharField(max_length=255)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
