# Proposal — Overpayment: Pending Carry → Refund or Credit at Enlist

Last updated: 2026-06-10  
**Bundle:** `61026.2/overpayment/`  
**Status:** Approved direction — **not implemented**  
**Build scope (phase 1):** **Registrar only** — see `IMPLEMENTATION_PLAN_OVERPAYMENT.md`; Enrollment deferred  
**Related:** `../docs/handoff/MASTER_DEMO_UAT_MANUAL.md` BAL-T04, Session F4; **`IMPLEMENTATION_PLAN_OVERPAYMENT.md`** (separate document, same folder)

---

## 1. Agreed business logic

When a student **overpays** a term, the school owes them money. The agreed flow:

```text
Term close detects overpay
        ↓
Surplus posted to next-term ledger as PENDING (not auto-applied to fees)
        ↓
Student returns for next term → cashier / enlist
        ↓
System prompts: Refund as cash  OR  Apply as credit to this term
        ↓
Ledger updated; enlistment and payment continue
```

| Path | Meaning |
|------|---------|
| **Refund as cash** | School pays student back; pending balance cleared; **does not** reduce next-term assessment |
| **Apply as credit** | Pending converts to `FORWARDED_BALANCE` credit; **reduces** this term’s total due |

**Debt forward** (student owes prior term) is **unchanged**: `FORWARDED_BALANCE` debit, enlist blocked if ≥ `ACCOUNTING_BLOCK_THRESHOLD`. The prompt applies only to **overpay** (pending credit).

---

## 2. Current behavior (what we are changing)

### 2.1 Today

On term close (`closeTermAndForwardBalance` in Enrollment + Registrar):

| `oldBalance` | Posting |
|--------------|---------|
| `> 0` | `FORWARDED_BALANCE` debit (debt) |
| `< 0` | `FORWARDED_BALANCE` credit — **auto-applied** to next term via `totalAssessment + forward_net` |
| ≈ 0 | Nothing |

There is **no student choice**. Credit hits assessment **immediately** when cashier opens the student.

### 2.2 Target

| `oldBalance` | Posting |
|--------------|---------|
| `> 0` | `FORWARDED_BALANCE` debit (unchanged) |
| `< 0` | `PENDING_TERM_CREDIT` credit — **held**, excluded from assessment until disposition |
| ≈ 0 | Nothing |

Disposition happens at **next-term enlist / first cashier session**, not at term close.

---

## 3. Ledger model

### 3.1 Transaction types

| Type | debit | credit | In `forward_net`? | In assessment? |
|------|-------|--------|-------------------|----------------|
| `FORWARDED_BALANCE` | prior debt | applied credit (after opt-in) | **Yes** | Yes (signed) |
| `PENDING_TERM_CREDIT` | disposition / refund | term-close overpay | **No** | **No** until resolved |
| `REFUND_PAYOUT` | cash refund issued | — | No | No |
| `REFUND` | — | drop overpay (current term) | No | Current-term only |

**Pending balance:**

```sql
pending_credit = COALESCE(SUM(credit),0) - COALESCE(SUM(debit),0)
FROM student_ledger
WHERE student_id = ? AND transaction_type = 'PENDING_TERM_CREDIT'
```

**Forward net** (unchanged formula — pending excluded):

```sql
forward_net = COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0)
FROM student_ledger
WHERE student_id = ? AND transaction_type = 'FORWARDED_BALANCE'
```

### 3.2 Disposition actions

**Apply as credit** (amount ≤ pending):

```text
PENDING_TERM_CREDIT  debit   (reduce pending)
FORWARDED_BALANCE    credit  (activate credit on account)
```

**Refund as cash** (amount ≤ pending):

```text
PENDING_TERM_CREDIT  debit   (reduce pending)
REFUND_PAYOUT        debit   (audit trail; optional mirror in payments)
```

Partial disposition allowed (e.g. refund ₱2,000, credit ₱2,500).

### 3.3 Term-close snapshot

`student_term_closes.forward_net` continues to store signed `oldBalance` at close (can be negative). Add optional column `pending_credit` in a later migration, or derive from ledger.

### 3.4 Drop `REFUND` vs term overpay

- **Drop `REFUND`**: stays on **current** ledger until term close.
- At close, surplus (including drop refunds) rolls into **`PENDING_TERM_CREDIT`**, not straight to `FORWARDED_BALANCE`.

---

## 4. UX — when the student is asked

### 4.1 Trigger

Show disposition UI when **all** of:

1. Student is on a **new** term (after term change / transition), and  
2. `pending_credit > 0.01`, and  
3. Disposition not yet recorded for this pending batch (see §4.3).

**Phase 1 surfaces (Registrar-only build):**

| Surface | When |
|---------|------|
| **Registrar Student Manager** | Pending balance + refund / apply credit / split |
| **Registrar enrollment hub** (`/admin/enrollment`) | Warning + block `canEnroll` until resolved |

**Deferred to Enrollment phase:** Cashier (`/admin/cashier`), Enrollment enlist finalize (`/admin/enlistment`).

Do **not** prompt at term close (student often absent; bulk transition has no modal).

### 4.2 Modal copy (draft)

> **Prior-term overpayment: ₱X,XXX.XX**  
> Choose how to apply this amount:  
> - **Refund as cash** — school returns this amount; it will not reduce this term’s fees.  
> - **Apply as credit** — reduces this term’s assessment.  
> Optional: split amount between both.

### 4.3 Idempotency / “already decided”

Store disposition audit (recommended):

```sql
CREATE TABLE student_overpay_dispositions (
  disposition_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id VARCHAR(100) NOT NULL,
  source_closing_sl VARCHAR(32) NULL,
  pending_amount DECIMAL(12,2) NOT NULL,
  refunded_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  credited_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  decided_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_by VARCHAR(100) NULL,
  remarks VARCHAR(255) NULL,
  KEY idx_overpay_disp_student (student_id)
);
```

If pending ledger balance is 0 but disposition row exists → no re-prompt.

### 4.4 Gating rules

| Action | Pending credit unresolved? | Phase 1 (Registrar) |
|--------|----------------------------|---------------------|
| Walk-in payment (Enrollment) | Allow | Unchanged — Enrollment not in scope |
| Registrar enrollment hub (`canEnroll`) | **Block** | **Yes** |
| Enrollment finalize enlist | Block | **Deferred** |
| Assessment display (Registrar) | **Exclude** pending from `totalAssessment` | **Yes** |

Rationale: student may pay new-term fees while deciding on old overpay; registrar advising enroll is the checkpoint until Enrollment phase adds cashier/enlist gates.

---

## 5. Assessment math (after change)

```text
totalAssessment = currentTermFees + forward_net     -- forward_net ≥ 0 typical; credit only after opt-in
outstanding     = max(0, totalAssessment - termPayments - scholarship)

-- Display-only line:
pendingOverpay    = pending_credit                  -- not in outstanding until credited
```

**After “Apply as credit”:** `forward_net` becomes negative (or less positive), `outstanding` drops.

---

## 6. Bulk term transition (Registrar Settings)

- Per student: `closeTermAndForwardBalance` posts `PENDING_TERM_CREDIT` for overpay (same as cashier advance).
- No per-student modal during bulk run.
- Disposition deferred until each student hits cashier/enlist.

---

## 7. Migration / backward compatibility

| Existing data | Treatment |
|---------------|-----------|
| Negative `FORWARDED_BALANCE` (already credited) | **Leave as-is** — treat as legacy “already applied credit”; no re-prompt |
| New term closes after deploy | Use `PENDING_TERM_CREDIT` path |

Optional one-time script: move negative `FORWARDED_BALANCE` → `PENDING_TERM_CREDIT` only in **demo** DBs if re-testing BAL-T04 from scratch.

---

## 8. Out of scope (v1)

- Admission / applicant reservation overpay pooling  
- Interest or expiry on pending credit  
- Student self-service portal (cashier/registrar only)  
- Finance Policy auto-default without prompt (always prompt when pending > 0)

---

## 9. Testing (UAT)

| ID | Scenario |
|----|----------|
| OPAY-01 | Overpay ₱2,500 → close → pending ₱2,500, `forward_net` = 0, assessment **not** reduced |
| OPAY-02 | Open cashier next term → modal → **Apply credit** → `forward_net` = -₱2,500, assessment reduced |
| OPAY-03 | Same setup → **Refund cash** ₱2,500 → pending 0, assessment unchanged, refund audit row |
| OPAY-04 | Split: refund ₱1,000 + credit ₱1,500 |
| OPAY-05 | Debt forward ₱5,000 → no overpay modal; enlist blocked per threshold |
| OPAY-06 | Finalize enlist blocked while pending > 0 and undecided |
| OPAY-07 | Bulk term transition → all overpays pending; disposition per student later |
| OPAY-08 | Regression: no overpay term close → behavior unchanged |

Update **BAL-T04** steps: overpay → advance → **pending** → choose credit → negative forward.

---

## 10. Related docs

| Doc | Purpose |
|-----|---------|
| `IMPLEMENTATION_PLAN_OVERPAYMENT.md` | **Separate** phased build plan (this folder) |
| `../docs/handoff/MASTER_DEMO_UAT_MANUAL.md` | BAL-T04, F4 |
| `../docs/handoff/PROJECT_STATUS_AND_ROADMAP.md` | Status tracking |
| `../README.md` | Full 61026.2 bundle index |
