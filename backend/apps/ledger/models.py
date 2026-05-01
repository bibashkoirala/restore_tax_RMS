from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


class PartyType(models.TextChoices):
    LANDLORD = 'landlord', 'Landlord'
    CLIENT = 'client', 'Client'
    MUNICIPALITY = 'municipality', 'Municipality'


class ContractStatus(models.TextChoices):
    PENDING_APPROVAL = 'pending_approval', 'Pending Approval'
    ACTIVE = 'active', 'Active'
    EXPIRED = 'expired', 'Expired'


class PaymentChannel(models.TextChoices):
    FONEPAY = 'fonepay', 'Fonepay'
    WALLET = 'wallet', 'Wallet'
    BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'


class TransactionType(models.TextChoices):
    RENT = 'rent', 'Rent'
    ELECTRICITY = 'electricity', 'Electricity'
    WATER = 'water', 'Water'
    WASTE = 'waste_management', 'Waste Management'
    INTERNET = 'internet', 'Internet'
    OTHER = 'other', 'Other'


class TransactionStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    CLAIMED = 'claimed', 'Claimed'
    APPROVED = 'approved', 'Approved'
    FAILED = 'failed', 'Failed'
    DISPUTED = 'disputed', 'Disputed'


class NotificationType(models.TextChoices):
    CONTRACT_APPROVAL = 'contract_approval', 'Contract Approval'
    TRANSACTION_CLAIMED = 'transaction_claimed', 'Transaction Claimed'
    TRANSACTION_APPROVED = 'transaction_approved', 'Transaction Approved'
    SYSTEM = 'system', 'System'


class PartyQuerySet(models.QuerySet):
    def landlords(self):
        return self.filter(party_type=PartyType.LANDLORD)

    def clients(self):
        return self.filter(party_type=PartyType.CLIENT)

    def municipalities(self):
        return self.filter(party_type=PartyType.MUNICIPALITY)


class Party(models.Model):
    objects = PartyQuerySet.as_manager()

    name = models.CharField(max_length=255)
    username = models.CharField(max_length=64, unique=True)
    party_type = models.CharField(max_length=32, choices=PartyType.choices)
    government_identifier = models.CharField(max_length=64, blank=True)
    clients = models.ManyToManyField(
        'self',
        through='LandlordClientRelation',
        symmetrical=False,
        related_name='landlords',
    )

    def __str__(self) -> str:
        return f'{self.name} ({self.party_type})'


class RoleFilteredManager(models.Manager):
    def __init__(self, role: str):
        super().__init__()
        self.role = role

    def get_queryset(self):
        return super().get_queryset().filter(party_type=self.role)


class Landlord(Party):
    objects = RoleFilteredManager(PartyType.LANDLORD)

    class Meta:
        proxy = True
        verbose_name = 'Landlord'
        verbose_name_plural = 'Landlords'


class Client(Party):
    objects = RoleFilteredManager(PartyType.CLIENT)

    class Meta:
        proxy = True
        verbose_name = 'Client'
        verbose_name_plural = 'Clients'


class LandlordClientRelation(models.Model):
    landlord = models.ForeignKey(
        Party,
        on_delete=models.CASCADE,
        related_name='landlord_links',
    )
    client = models.ForeignKey(
        Party,
        on_delete=models.CASCADE,
        related_name='client_links',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['landlord', 'client'],
                name='unique_landlord_client_relation',
            ),
        ]
        ordering = ['landlord__name', 'client__name']

    def clean(self):
        if self.landlord_id == self.client_id:
            raise ValidationError('Landlord and client must be different users.')
        if self.landlord.party_type != PartyType.LANDLORD:
            raise ValidationError({'landlord': 'Selected party must be a landlord.'})
        if self.client.party_type != PartyType.CLIENT:
            raise ValidationError({'client': 'Selected party must be a client.'})

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        return f'{self.landlord.name} -> {self.client.name}'


class Contract(models.Model):
    code = models.CharField(max_length=64, unique=True, blank=True)
    landlord = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='landlord_contracts',
    )
    client = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='client_contracts',
    )
    municipality = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='municipality_contracts',
    )
    start_date = models.DateField()
    end_date = models.DateField()
    base_rent = models.DecimalField(max_digits=12, decimal_places=2)
    annual_increment_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
    )
    recurring_charges = models.JSONField(default=list, blank=True)
    optional_terms = models.JSONField(default=list, blank=True)
    status = models.CharField(
        max_length=32,
        choices=ContractStatus.choices,
        default=ContractStatus.PENDING_APPROVAL,
    )
    approved_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.code:
            last_id = (
                Contract.objects.order_by('-id')
                .values_list('id', flat=True)
                .first()
                or 0
            )
            self.code = f'CTR-{last_id + 1:04d}'
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        return self.code


class Transaction(models.Model):
    contract = models.ForeignKey(
        Contract,
        on_delete=models.PROTECT,
        related_name='transactions',
    )
    transaction_type = models.CharField(
        max_length=32,
        choices=TransactionType.choices,
    )
    status = models.CharField(
        max_length=32,
        choices=TransactionStatus.choices,
        default=TransactionStatus.PENDING,
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    charge_label = models.CharField(max_length=128, blank=True, default='')

    payer = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='payments_made',
    )
    payee = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='payments_received',
    )

    payment_channel = models.CharField(
        max_length=32,
        choices=PaymentChannel.choices,
    )
    payment_reference = models.CharField(max_length=128)
    occurred_at = models.DateTimeField()
    claimed_by = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='claimed_transactions',
        null=True,
        blank=True,
    )
    approved_by = models.ForeignKey(
        Party,
        on_delete=models.PROTECT,
        related_name='approved_transactions',
        null=True,
        blank=True,
    )
    claimed_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-occurred_at']

    def claim(self, actor: Party):
        self.status = TransactionStatus.CLAIMED
        self.claimed_by = actor
        self.claimed_at = timezone.now()
        self.save(
            update_fields=['status', 'claimed_by', 'claimed_at'],
        )

    def approve(self, actor: Party):
        self.status = TransactionStatus.APPROVED
        self.approved_by = actor
        self.approved_at = timezone.now()
        self.save(
            update_fields=['status', 'approved_by', 'approved_at'],
        )


class AuditLog(models.Model):
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.PROTECT,
        related_name='audit_logs',
        null=True,
        blank=True,
    )
    actor = models.ForeignKey(Party, on_delete=models.PROTECT)
    action = models.CharField(max_length=255)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class Notification(models.Model):
    recipient = models.ForeignKey(
        Party,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(
        max_length=32,
        choices=NotificationType.choices,
        default=NotificationType.SYSTEM,
    )
    contract = models.ForeignKey(
        Contract,
        on_delete=models.CASCADE,
        related_name='notifications',
        null=True,
        blank=True,
    )
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='notifications',
        null=True,
        blank=True,
    )
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
