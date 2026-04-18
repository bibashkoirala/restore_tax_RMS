from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.ledger.views import ContractViewSet, PeriodSummaryViewSet, TransactionViewSet

router = DefaultRouter()
router.register(r'contracts', ContractViewSet, basename='contract')
router.register(r'transactions', TransactionViewSet, basename='transaction')
router.register(r'summaries', PeriodSummaryViewSet, basename='summary')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include(router.urls)),
]
