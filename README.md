# Restored Tax Management System (RTMS)

RTMS is a transparency-first transaction recording platform designed for municipality-level offices in Nepal and authorized third-party organizations.

## Product vision

This platform is **not a rent management app**. It focuses on:

- Tripartite accountability among:
  - Landlord
  - Client/Tenant
  - Government/Municipality
- Contract-based payment tracking
- Automatic contract-driven rent updates
- Utility transaction tracking (electricity, water, waste management)
- Audit logs for every action and payment event
- Weekly, monthly, quarterly, and yearly reports
- Future integration with Nepali payment channels (e.g., Fonepay) and free wallet tools

## Monorepo layout

- `frontend/mobile_app`: Flutter mobile-first app (web-support friendly architecture)
- `backend`: Django + DRF API scaffold
- `docs`: Architecture, roadmap, and integration notes

## Current delivery status

### M1 (mobile foundation) ✅

- Government-inspired minimal red/black theme
- Contract + transaction domain models
- Period filter for weekly/monthly/quarterly/yearly ledger summaries
- Transaction cards and audit log feed

### M2 (backend scaffold) ✅

- Django project + DRF integration
- Ledger data models (party/contract/transaction/audit log)
- Read-only contract/transaction endpoints
- Period summary endpoint for municipality reporting windows

## Quick start (backend)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Next milestones

1. Role-based auth and scoped access (landlord/client/municipality/auditor)
2. Fonepay/wallet adapter service with callback validation
3. Government report exports (PDF/CSV) and digital signature pipeline
4. Full Flutter web build with authenticated API integration
