from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import (
    AuditLog,
    LandlordClientRelation,
    Contract,
    ContractStatus,
    Notification,
    NotificationType,
    Party,
    PartyType,
    Transaction,
    TransactionStatus,
)
from .serializers import (
    ContractCreateSerializer,
    ContractSerializer,
    NotificationSerializer,
    PaymentCreateSerializer,
    TransactionSerializer,
    UserOverviewSerializer,
)


def _party_for_request(request):
    username = request.query_params.get('username') or request.data.get('username')
    if not username:
        return None
    return Party.objects.filter(username=username).first()


def _transaction_type_for_label(label):
    normalized = label.lower()
    if 'rent' in normalized:
        return 'rent'
    if 'electric' in normalized:
        return 'electricity'
    if 'water' in normalized:
        return 'water'
    if 'waste' in normalized:
        return 'waste_management'
    if 'internet' in normalized:
        return 'internet'
    return 'other'


class ContractViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    queryset = Contract.objects.select_related('landlord', 'client', 'municipality')
    permission_classes = [AllowAny]

    def get_serializer_class(self):
        if self.action == 'create':
            return ContractCreateSerializer
        return ContractSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        party = _party_for_request(self.request)
        if not party:
            return qs

        if party.party_type == PartyType.MUNICIPALITY:
            return qs.filter(municipality=party)
        if party.party_type == PartyType.LANDLORD:
            return qs.filter(landlord=party)
        return qs.filter(client=party)

    def create(self, request, *args, **kwargs):
        actor = _party_for_request(request)
        if not actor:
            return Response({'detail': 'username is required.'}, status=400)
        if actor.party_type != PartyType.LANDLORD:
            return Response(
                {'detail': 'Only landlords can create contracts.'},
                status=403,
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        municipality_id = serializer.validated_data.get('municipality_id')
        municipality = None
        if municipality_id is not None:
            municipality = Party.objects.filter(
                id=municipality_id,
                party_type=PartyType.MUNICIPALITY,
            ).first()
        if municipality is None:
            municipality = (
                Contract.objects.filter(landlord=actor)
                .select_related('municipality')
                .values_list('municipality_id', flat=True)
                .first()
            )
            municipality = (
                Party.objects.filter(id=municipality, party_type=PartyType.MUNICIPALITY).first()
                if municipality
                else Party.objects.filter(party_type=PartyType.MUNICIPALITY).first()
            )

        if municipality is None:
            return Response(
                {'detail': 'A municipality user is required to create a contract.'},
                status=400,
            )

        client = Party.objects.get(id=serializer.validated_data['client_id'])
        contract = Contract.objects.create(
            landlord=actor,
            client=client,
            municipality=municipality,
            start_date=serializer.validated_data['start_date'],
            end_date=serializer.validated_data['end_date'],
            base_rent=serializer.validated_data['base_rent'],
            annual_increment_percent=serializer.validated_data['annual_increment_percent'],
            recurring_charges=serializer.validated_data['recurring_charges'],
            optional_terms=serializer.validated_data.get('optional_terms', []),
        )
        LandlordClientRelation.objects.get_or_create(
            landlord=actor,
            client=client,
        )

        Notification.objects.create(
            recipient=client,
            contract=contract,
            notification_type=NotificationType.SYSTEM,
            title='New Contract Shared',
            message=(
                f'{actor.name} shared contract {contract.code} with you. '
                f'Open the contract list to review the monthly terms.'
            ),
        )
        AuditLog.objects.create(
            actor=actor,
            action='Contract Created',
            metadata={
                'contract_code': contract.code,
                'client_id': client.id,
            },
        )

        output = ContractSerializer(contract, context=self.get_serializer_context())
        return Response(output.data, status=201)

    @action(detail=True, methods=['post'])
    def pay(self, request, pk=None):
        contract = self.get_object()
        actor = _party_for_request(request)

        if not actor:
            return Response({'detail': 'username is required.'}, status=400)
        if actor.party_type != PartyType.CLIENT or contract.client_id != actor.id:
            return Response(
                {'detail': 'Only the contract client can submit a payment.'},
                status=403,
            )

        serializer = PaymentCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payment = Transaction.objects.create(
            contract=contract,
            transaction_type=_transaction_type_for_label(
                serializer.validated_data['charge_label'],
            ),
            charge_label=serializer.validated_data['charge_label'],
            status=TransactionStatus.CLAIMED,
            amount=serializer.validated_data['amount'],
            payer=actor,
            payee=contract.landlord,
            payment_channel='wallet',
            payment_reference=f'PAY-{timezone.now().strftime("%Y%m%d%H%M%S%f")}',
            occurred_at=timezone.now(),
            claimed_by=actor,
            claimed_at=timezone.now(),
        )

        Notification.objects.create(
            recipient=contract.landlord,
            contract=contract,
            transaction=payment,
            notification_type=NotificationType.TRANSACTION_CLAIMED,
            title='Payment Waiting Approval',
            message=(
                f'{actor.name} paid NPR {payment.amount} for '
                f'{payment.charge_label or payment.get_transaction_type_display()} '
                f'in {contract.code}.'
            ),
        )
        AuditLog.objects.create(
            transaction=payment,
            actor=actor,
            action='Payment Submitted',
            metadata={
                'payment_reference': payment.payment_reference,
                'charge_label': payment.charge_label,
                'contract_code': contract.code,
            },
        )

        output = TransactionSerializer(payment, context={'party': actor})
        return Response(output.data, status=201)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        contract = self.get_object()
        actor = _party_for_request(request)

        if not actor:
            return Response({'detail': 'username is required.'}, status=400)
        if actor.party_type != PartyType.LANDLORD or contract.landlord_id != actor.id:
            return Response(
                {'detail': 'Only the landlord for this contract can approve it.'},
                status=403,
            )

        contract.status = ContractStatus.ACTIVE
        contract.approved_at = timezone.now()
        contract.save(update_fields=['status', 'approved_at', 'updated_at'])

        Notification.objects.create(
            recipient=contract.client,
            contract=contract,
            notification_type=NotificationType.CONTRACT_APPROVAL,
            title='Contract Approved',
            message=f'Your contract {contract.code} was approved by {actor.name}.',
        )
        AuditLog.objects.create(
            actor=actor,
            action='Contract Approved',
            metadata={'contract_code': contract.code},
        )

        return Response(self.get_serializer(contract).data)


class TransactionViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    queryset = Transaction.objects.select_related(
        'contract',
        'contract__landlord',
        'contract__client',
        'contract__municipality',
        'payer',
        'payee',
        'claimed_by',
        'approved_by',
    ).prefetch_related('audit_logs__actor')
    serializer_class = TransactionSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        party = _party_for_request(self.request)
        if not party:
            return qs

        if party.party_type == PartyType.MUNICIPALITY:
            return qs.filter(contract__municipality=party)
        if party.party_type == PartyType.LANDLORD:
            return qs.filter(contract__landlord=party)
        return qs.filter(contract__client=party)

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['party'] = _party_for_request(self.request)
        return context

    @action(detail=True, methods=['post'])
    def claim(self, request, pk=None):
        transaction = self.get_object()
        actor = _party_for_request(request)

        if not actor:
            return Response({'detail': 'username is required.'}, status=400)
        if actor.party_type != PartyType.CLIENT or transaction.contract.client_id != actor.id:
            return Response(
                {'detail': 'Only the contract client can claim this transaction.'},
                status=403,
            )
        if transaction.status != TransactionStatus.PENDING:
            return Response(
                {'detail': 'Only pending transactions can be claimed.'},
                status=400,
            )

        transaction.claim(actor)
        Notification.objects.create(
            recipient=transaction.contract.landlord,
            contract=transaction.contract,
            transaction=transaction,
            notification_type=NotificationType.TRANSACTION_CLAIMED,
            title='Transaction Claimed',
            message=(
                f'{actor.name} claimed transaction '
                f'{transaction.payment_reference} for {transaction.contract.code}.'
            ),
        )
        AuditLog.objects.create(
            transaction=transaction,
            actor=actor,
            action='Transaction Claimed',
            metadata={
                'payment_reference': transaction.payment_reference,
                'contract_code': transaction.contract.code,
            },
        )

        serializer = self.get_serializer(transaction)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        transaction = self.get_object()
        actor = _party_for_request(request)

        if not actor:
            return Response({'detail': 'username is required.'}, status=400)
        if actor.party_type != PartyType.LANDLORD or transaction.contract.landlord_id != actor.id:
            return Response(
                {'detail': 'Only the contract landlord can approve this transaction.'},
                status=403,
            )
        if transaction.status != TransactionStatus.CLAIMED:
            return Response(
                {'detail': 'Only claimed transactions can be approved.'},
                status=400,
            )

        transaction.approve(actor)
        Notification.objects.create(
            recipient=transaction.contract.client,
            contract=transaction.contract,
            transaction=transaction,
            notification_type=NotificationType.TRANSACTION_APPROVED,
            title='Transaction Approved',
            message=(
                f'{actor.name} approved transaction '
                f'{transaction.payment_reference} for {transaction.contract.code}.'
            ),
        )
        Notification.objects.create(
            recipient=transaction.contract.municipality,
            contract=transaction.contract,
            transaction=transaction,
            notification_type=NotificationType.SYSTEM,
            title='Contract Ledger Updated',
            message=(
                f'Payment {transaction.payment_reference} for '
                f'{transaction.contract.code} was approved and the contract ledger changed.'
            ),
        )
        AuditLog.objects.create(
            transaction=transaction,
            actor=actor,
            action='Transaction Approved',
            metadata={
                'payment_reference': transaction.payment_reference,
                'contract_code': transaction.contract.code,
            },
        )

        serializer = self.get_serializer(transaction)
        return Response(serializer.data)


class NotificationViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        party = _party_for_request(self.request)
        if not party:
            return Notification.objects.none()
        return Notification.objects.filter(recipient=party).select_related(
            'contract',
            'transaction',
        )


class UserOverviewViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]

    def list(self, request):
        party = _party_for_request(request)
        if not party:
            return Response({'detail': 'username is required.'}, status=400)

        if party.party_type == PartyType.MUNICIPALITY:
            contracts = Contract.objects.filter(municipality=party)
            transactions = Transaction.objects.filter(contract__municipality=party)
        elif party.party_type == PartyType.LANDLORD:
            contracts = Contract.objects.filter(landlord=party)
            transactions = Transaction.objects.filter(contract__landlord=party)
        else:
            contracts = Contract.objects.filter(client=party)
            transactions = Transaction.objects.filter(contract__client=party)

        contracts = contracts.select_related('landlord', 'client', 'municipality')
        transactions = transactions.select_related(
            'contract',
            'contract__landlord',
            'contract__client',
            'contract__municipality',
            'payer',
            'payee',
            'claimed_by',
            'approved_by',
        ).prefetch_related('audit_logs__actor')
        notifications = Notification.objects.filter(recipient=party).select_related(
            'contract',
            'transaction',
        )

        serializer = UserOverviewSerializer(
            {
                'user': party,
                'contracts': contracts,
                'transactions': transactions,
                'notifications': notifications,
            },
            context={'party': party},
        )
        return Response(serializer.data)


class PeriodSummaryViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]

    def list(self, request):
        contract_id = request.query_params.get('contract_id')
        start = parse_date(request.query_params.get('start', ''))
        end = parse_date(request.query_params.get('end', ''))
        party = _party_for_request(request)

        if not (contract_id and start and end):
            return Response(
                {'detail': 'contract_id, start and end are required query params.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qs = Transaction.objects.filter(
            contract_id=contract_id,
            occurred_at__date__gte=start,
            occurred_at__date__lte=end,
        )

        if party:
            if party.party_type == PartyType.MUNICIPALITY:
                qs = qs.filter(contract__municipality=party)
            elif party.party_type == PartyType.LANDLORD:
                qs = qs.filter(contract__landlord=party)
            else:
                qs = qs.filter(contract__client=party)

        by_type = qs.values('transaction_type').annotate(total=Sum('amount')).order_by(
            'transaction_type'
        )
        total = qs.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        return Response(
            {
                'contract_id': int(contract_id),
                'start': start,
                'end': end,
                'total': total,
                'breakdown': list(by_type),
                'count': qs.count(),
            }
        )
