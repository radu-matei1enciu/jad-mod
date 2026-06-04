## Original problem / solution text
 
| Use case | Problem | Solution |
|---|---|---|
| 3 Near-real-time QC data exchange with external labs (CTOs) | UCB QP/QC teams in Belgium wait long time periods to receive complete Certificates of Analysis (CoA), raw data files, and deviation summaries from external testing labs; data arrives as PDFs via email and needs manual transcription, slowing batch certification. | Implement a secure data exchange (APIs/SFTP) between partner Laboratory Information Management System (LIMS) and UCB QMS/eBR to push structured QC results (JSON/CSV + e-signatures) as soon as tests are approved. Use common dictionaries (test IDs, specs) and automated completeness checks. Scenario: when partner lab approves assay, chromatograms + results are auto-published to UCB, pre-populating eBR (e-Batch Record) and triggering QA review. |
 
---
 
## Flat data model for demo
 
For the demo, we use one simple denormalized class:
 
```text
QcResult
- id
- batchId
- product
- test
- result
- specification
- status
- approvedAt
```
 
Each `QcResult` represents one approved QC test result coming from the external lab API.
 
---
 
## Field meaning
 
| Field | Meaning | Example |
|---|---|---|
| `id` | Unique QC result ID | `QC-001` |
| `batchId` | Batch tested | `BATCH-2026-001` |
| `product` | Product name or code | `Product A` |
| `test` | QC test name | `Potency` |
| `result` | Actual result value | `98.7%` |
| `specification` | Expected range or limit | `95–105%` |
| `status` | Result status | `PASS` |
| `approvedAt` | Time the result was approved by the lab | `2026-06-04T08:32:00Z` |
 
---
 
## Example JSON returned by the API
 
```json
[
  {
    "id": "QC-001",
    "batchId": "BATCH-2026-001",
    "product": "Product A",
    "test": "Potency",
    "result": "98.7%",
    "specification": "95–105%",
    "status": "PASS",
    "approvedAt": "2026-06-04T08:32:00Z"
  },
  {
    "id": "QC-002",
    "batchId": "BATCH-2026-001",
    "product": "Product A",
    "test": "Purity",
    "result": "99.1%",
    "specification": "≥98.0%",
    "status": "PASS",
    "approvedAt": "2026-06-04T08:35:00Z"
  },
  {
    "id": "QC-003",
    "batchId": "BATCH-2026-001",
    "product": "Product A",
    "test": "Endotoxin",
    "result": "0.04 EU/mL",
    "specification": "≤0.25 EU/mL",
    "status": "PASS",
    "approvedAt": "2026-06-04T08:39:00Z"
  },
  {
    "id": "QC-004",
    "batchId": "BATCH-2026-002",
    "product": "Product B",
    "test": "Assay",
    "result": "92.1%",
    "specification": "95–105%",
    "status": "FAIL",
    "approvedAt": "2026-06-04T08:41:00Z"
  }
]
```
 
---
 
## UI table
 
When UCB clicks **View Data**, show the same data as a simple table:
 
| ID | Batch | Product | Test | Result | Specification | Status | Approved At |
|---|---|---|---|---|---|---|---|
| QC-001 | BATCH-2026-001 | Product A | Potency | 98.7% | 95–105% | PASS | 08:32 |
| QC-002 | BATCH-2026-001 | Product A | Purity | 99.1% | ≥98.0% | PASS | 08:35 |
| QC-003 | BATCH-2026-001 | Product A | Endotoxin | 0.04 EU/mL | ≤0.25 EU/mL | PASS | 08:39 |
| QC-004 | BATCH-2026-002 | Product B | Assay | 92.1% | 95–105% | FAIL | 08:41 |
 
---
 
## Database table
 
```text
qc_result
- id
- batch_id
- product
- test
- result
- specification
- status
- approved_at
```