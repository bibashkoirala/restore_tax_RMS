# RTMS Architecture (Draft v0.2)

## 1) Core actors

1. **Landlord**: Receives contractual rent payments and utility settlement records.
2. **Client/Tenant**: Pays rent/utilities against contract terms.
3. **Government/Municipality**: Reviews compliance and transaction transparency.

## 2) Core modules

### A. Contract Ledger
- Stores contract terms (start/end date, rent amount, escalation rule)
- Supports automatic periodic rent update rules

### B. Transaction Ledger
- Records primary and utility transactions
- Tags each entry by period and party
- Prepares period snapshots: weekly/monthly/quarterly/yearly

### C. Audit Trail
- Immutable event log for:
  - transaction created/edited/verified
  - status transitions
  - payer/payee confirmations

### D. Payment Gateway Adapter
- Pluggable interface for Fonepay and wallet providers
- Handles callbacks and receipt reference IDs

### E. Reporting & Compliance
- Party-wise report
- Municipality summary report
- Export-ready structure for PDF/CSV in backend phase

## 3) Implemented backend scaffold (Django + DRF)

- Project: `backend/rtms_backend`
- App: `backend/apps/ledger`
- Models:
  - `Party`
  - `Contract`
  - `Transaction`
  - `AuditLog`
- Endpoints:
  - `GET /api/v1/contracts/`
  - `GET /api/v1/contracts/{id}/`
  - `GET /api/v1/transactions/`
  - `GET /api/v1/transactions/{id}/`
  - `GET /api/v1/summaries/?contract_id=<id>&start=YYYY-MM-DD&end=YYYY-MM-DD`

## 4) Frontend (Flutter mobile-first)

- Dashboard with report period selector: weekly/monthly/quarterly/yearly
- Ledger summary cards + transaction feed + audit feed
- Government red/black visual identity with neutral background

## 5) Compliance and security notes

- Full auditability of mutation actions
- Soft-delete avoided for financial records; prefer append-only revisions
- Nepal-localized fiscal date support can be added using Bikram Sambat converters
- Government report payloads should be signed/hashed in backend
