from decimal import Decimal

from django.db.models import Sum
from django.utils.dateparse import parse_date
from rest_framework import mixins, status, viewsets
from rest_framework.response import Response

from .models import Contract, Transaction
from .serializers import ContractSerializer, TransactionSerializer


class ContractViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    queryset = Contract.objects.select_related('landlord', 'client', 'municipality')
    serializer_class = ContractSerializer


class TransactionViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    queryset = Transaction.objects.select_related('contract', 'payer', 'payee').prefetch_related('audit_logs__actor')
    serializer_class = TransactionSerializer


class PeriodSummaryViewSet(viewsets.ViewSet):
    """
    Query params:
    - contract_id: int (required)
    - start: YYYY-MM-DD (required)
    - end: YYYY-MM-DD (required)
    """

    def list(self, request):
        contract_id = request.query_params.get('contract_id')
        start = parse_date(request.query_params.get('start', ''))
        end = parse_date(request.query_params.get('end', ''))

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

        by_type = (
            qs.values('transaction_type')
            .annotate(total=Sum('amount'))
            .order_by('transaction_type')
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
