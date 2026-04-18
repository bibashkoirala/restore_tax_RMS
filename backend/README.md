# Django Backend (M2 scaffold)

This directory contains a runnable Django + DRF scaffold for the RTMS backend.

## What is implemented

- Django project: `rtms_backend`
- Ledger app: `apps.ledger`
- Models:
  - `Party` (`landlord`, `client`, `municipality`)
  - `Contract`
  - `Transaction` (rent + utility transaction types, status, payment channel)
  - `AuditLog`
- Read-only API endpoints (list/retrieve):
  - `/api/v1/contracts/`
  - `/api/v1/transactions/`
- Period summary API endpoint:
  - `/api/v1/summaries/?contract_id=1&start=2026-04-01&end=2026-04-30`
- Automated API tests for summary aggregation and validation.

## Configuration

Environment variables supported:

- `DJANGO_SECRET_KEY` (default dev key)
- `DJANGO_DEBUG` (`true`/`false`)
- `DJANGO_ALLOWED_HOSTS` (comma-separated)
- `DB_ENGINE` (defaults to SQLite engine)
- `DB_NAME` (defaults to `db.sqlite3`)

## Local run

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Run tests

```bash
python manage.py test apps.ledger.tests
```

## Notes

- Default database is SQLite for local development.
- API permissions are currently `IsAuthenticated` by default in DRF settings.
- Fonepay/wallet callback handlers will be added in the next API iteration.
