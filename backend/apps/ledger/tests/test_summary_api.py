from datetime import date, datetime
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase

from apps.ledger.models import (
    Contract,
    Party,
    PartyType,
    PaymentChannel,
    Transaction,
    TransactionStatus,
    TransactionType,
)


class PeriodSummaryApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='tester',
            password='test-pass-123',
        )
        self.client.force_authenticate(user=self.user)

        self.landlord = Party.objects.create(name='Hari', party_type=PartyType.LANDLORD)
        self.client_party = Party.objects.create(name='Sita', party_type=PartyType.CLIENT)
        self.municipality = Party.objects.create(
            name='Kathmandu Ward 5',
            party_type=PartyType.MUNICIPALITY,
        )
        self.contract = Contract.objects.create(
            code='C-2001',
            landlord=self.landlord,
            client=self.client_party,
            municipality=self.municipality,
            start_date=date(2026, 1, 1),
            end_date=date(2028, 12, 31),
            base_rent=Decimal('25000.00'),
            annual_increment_percent=Decimal('5.00'),
        )

    def _create_tx(self, tx_type: str, amount: str, occurred_at: datetime) -> None:
        Transaction.objects.create(
            contract=self.contract,
            transaction_type=tx_type,
            status=TransactionStatus.COMPLETED,
            amount=Decimal(amount),
            payer=self.client_party,
            payee=self.landlord,
            payment_channel=PaymentChannel.WALLET,
            payment_reference=f'REF-{tx_type}-{amount}',
            occurred_at=occurred_at,
        )

    def test_returns_aggregated_summary_for_date_range(self):
        self._create_tx(TransactionType.RENT, '25000.00', datetime(2026, 4, 1, 8, 0))
        self._create_tx(TransactionType.ELECTRICITY, '2500.00', datetime(2026, 4, 2, 8, 0))
        self._create_tx(TransactionType.WATER, '500.00', datetime(2026, 3, 1, 8, 0))

        url = reverse('summary-list')
        response = self.client.get(
            url,
            {
                'contract_id': self.contract.id,
                'start': '2026-04-01',
                'end': '2026-04-30',
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['count'], 2)
        self.assertEqual(Decimal(response.data['total']), Decimal('27500.00'))

        breakdown = {item['transaction_type']: Decimal(item['total']) for item in response.data['breakdown']}
        self.assertEqual(breakdown[TransactionType.RENT], Decimal('25000.00'))
        self.assertEqual(breakdown[TransactionType.ELECTRICITY], Decimal('2500.00'))

    def test_returns_400_when_required_params_missing(self):
        url = reverse('summary-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 400)
