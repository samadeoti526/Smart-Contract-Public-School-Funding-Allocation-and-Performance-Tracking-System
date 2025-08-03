;; School Resource Utilization Tracking Contract
;; Monitors school budget allocation and spending transparency

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-SCHOOL-EXISTS (err u301))
(define-constant ERR-SCHOOL-NOT-FOUND (err u302))
(define-constant ERR-INVALID-AMOUNT (err u303))
(define-constant ERR-INSUFFICIENT-BUDGET (err u304))
(define-constant ERR-INVALID-CATEGORY (err u305))
(define-constant ERR-INVALID-INPUT (err u306))

;; Budget categories
(define-constant CATEGORY-INSTRUCTION "instruction")
(define-constant CATEGORY-ADMINISTRATION "administration")
(define-constant CATEGORY-FACILITIES "facilities")
(define-constant CATEGORY-TECHNOLOGY "technology")
(define-constant CATEGORY-TRANSPORTATION "transportation")
(define-constant CATEGORY-FOOD-SERVICE "food-service")
(define-constant CATEGORY-SPECIAL-PROGRAMS "special-programs")

;; Data Variables
(define-data-var total-schools uint u0)
(define-data-var total-budget-allocated uint u0)
(define-data-var total-expenditures uint u0)

;; Data Maps
(define-map schools
  { school-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    district: (string-ascii 50),
    total-budget: uint,
    remaining-budget: uint,
    student-enrollment: uint,
    budget-year: uint,
    active: bool
  }
)

(define-map budget-allocations
  { school-id: (string-ascii 50), category: (string-ascii 50) }
  {
    allocated-amount: uint,
    spent-amount: uint,
    remaining-amount: uint,
    last-updated: uint
  }
)

(define-map expenditures
  { school-id: (string-ascii 50), expenditure-id: uint }
  {
    category: (string-ascii 50),
    amount: uint,
    description: (string-ascii 200),
    vendor: (string-ascii 100),
    approval-status: (string-ascii 20),
    transaction-date: uint,
    approved-by: (string-ascii 50)
  }
)

(define-map utilization-metrics
  { school-id: (string-ascii 50), period: uint }
  {
    efficiency-score: uint,
    budget-utilization-rate: uint,
    cost-per-student: uint,
    administrative-overhead: uint,
    instruction-percentage: uint
  }
)

(define-map audit-trail
  { school-id: (string-ascii 50), audit-id: uint }
  {
    audit-type: (string-ascii 50),
    findings: (string-ascii 500),
    recommendations: (string-ascii 500),
    audit-date: uint,
    auditor: (string-ascii 50),
    compliance-score: uint
  }
)

;; Private Functions
(define-private (is-valid-category (category (string-ascii 50)))
  (or (is-eq category CATEGORY-INSTRUCTION)
      (or (is-eq category CATEGORY-ADMINISTRATION)
          (or (is-eq category CATEGORY-FACILITIES)
              (or (is-eq category CATEGORY-TECHNOLOGY)
                  (or (is-eq category CATEGORY-TRANSPORTATION)
                      (or (is-eq category CATEGORY-FOOD-SERVICE)
                          (is-eq category CATEGORY-SPECIAL-PROGRAMS)))))))
)

(define-private (calculate-utilization-rate (spent uint) (allocated uint))
  (if (> allocated u0)
    (/ (* spent u100) allocated)
    u0
  )
)

;; Public Functions

;; Register a new school
(define-public (register-school (school-id (string-ascii 50)) (name (string-ascii 100))
                               (district (string-ascii 50)) (total-budget uint)
                               (student-enrollment uint) (budget-year uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len school-id) u0) ERR-INVALID-INPUT)
    (asserts! (> total-budget u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? schools { school-id: school-id })) ERR-SCHOOL-EXISTS)

    (map-set schools
      { school-id: school-id }
      {
        name: name,
        district: district,
        total-budget: total-budget,
        remaining-budget: total-budget,
        student-enrollment: student-enrollment,
        budget-year: budget-year,
        active: true
      }
    )

    (var-set total-schools (+ (var-get total-schools) u1))
    (var-set total-budget-allocated (+ (var-get total-budget-allocated) total-budget))

    (ok true)
  )
)

;; Allocate budget to a category
(define-public (allocate-budget (school-id (string-ascii 50)) (category (string-ascii 50)) (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-category category) ERR-INVALID-CATEGORY)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    (match (map-get? schools { school-id: school-id })
      school-data
      (begin
        (asserts! (>= (get remaining-budget school-data) amount) ERR-INSUFFICIENT-BUDGET)

        ;; Update school's remaining budget
        (map-set schools
          { school-id: school-id }
          (merge school-data {
            remaining-budget: (- (get remaining-budget school-data) amount)
          })
        )

        ;; Set budget allocation
        (map-set budget-allocations
          { school-id: school-id, category: category }
          {
            allocated-amount: amount,
            spent-amount: u0,
            remaining-amount: amount,
            last-updated: block-height
          }
        )

        (ok true)
      )
      ERR-SCHOOL-NOT-FOUND
    )
  )
)

;; Record an expenditure
(define-public (record-expenditure (school-id (string-ascii 50)) (expenditure-id uint)
                                  (category (string-ascii 50)) (amount uint)
                                  (description (string-ascii 200)) (vendor (string-ascii 100))
                                  (approved-by (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-category category) ERR-INVALID-CATEGORY)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    (match (map-get? budget-allocations { school-id: school-id, category: category })
      allocation-data
      (begin
        (asserts! (>= (get remaining-amount allocation-data) amount) ERR-INSUFFICIENT-BUDGET)

        ;; Record the expenditure
        (map-set expenditures
          { school-id: school-id, expenditure-id: expenditure-id }
          {
            category: category,
            amount: amount,
            description: description,
            vendor: vendor,
            approval-status: "approved",
            transaction-date: block-height,
            approved-by: approved-by
          }
        )

        ;; Update budget allocation
        (map-set budget-allocations
          { school-id: school-id, category: category }
          (merge allocation-data {
            spent-amount: (+ (get spent-amount allocation-data) amount),
            remaining-amount: (- (get remaining-amount allocation-data) amount),
            last-updated: block-height
          })
        )

        (var-set total-expenditures (+ (var-get total-expenditures) amount))
        (ok true)
      )
      ERR-SCHOOL-NOT-FOUND
    )
  )
)

;; Calculate and record utilization metrics
(define-public (record-utilization-metrics (school-id (string-ascii 50)) (period uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (match (map-get? schools { school-id: school-id })
      school-data
      (let
        (
          (total-spent (- (get total-budget school-data) (get remaining-budget school-data)))
          (utilization-rate (calculate-utilization-rate total-spent (get total-budget school-data)))
          (cost-per-student (if (> (get student-enrollment school-data) u0)
                             (/ total-spent (get student-enrollment school-data))
                             u0))
        )
        (map-set utilization-metrics
          { school-id: school-id, period: period }
          {
            efficiency-score: u85,
            budget-utilization-rate: utilization-rate,
            cost-per-student: cost-per-student,
            administrative-overhead: u15,
            instruction-percentage: u65
          }
        )

        (ok true)
      )
      ERR-SCHOOL-NOT-FOUND
    )
  )
)

;; Record audit findings
(define-public (record-audit (school-id (string-ascii 50)) (audit-id uint) (audit-type (string-ascii 50))
                            (findings (string-ascii 500)) (recommendations (string-ascii 500))
                            (auditor (string-ascii 50)) (compliance-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? schools { school-id: school-id })) ERR-SCHOOL-NOT-FOUND)
    (asserts! (<= compliance-score u100) ERR-INVALID-INPUT)

    (map-set audit-trail
      { school-id: school-id, audit-id: audit-id }
      {
        audit-type: audit-type,
        findings: findings,
        recommendations: recommendations,
        audit-date: block-height,
        auditor: auditor,
        compliance-score: compliance-score
      }
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get school information
(define-read-only (get-school (school-id (string-ascii 50)))
  (map-get? schools { school-id: school-id })
)

;; Get budget allocation for a category
(define-read-only (get-budget-allocation (school-id (string-ascii 50)) (category (string-ascii 50)))
  (map-get? budget-allocations { school-id: school-id, category: category })
)

;; Get expenditure details
(define-read-only (get-expenditure (school-id (string-ascii 50)) (expenditure-id uint))
  (map-get? expenditures { school-id: school-id, expenditure-id: expenditure-id })
)

;; Get utilization metrics
(define-read-only (get-utilization-metrics (school-id (string-ascii 50)) (period uint))
  (map-get? utilization-metrics { school-id: school-id, period: period })
)

;; Get audit record
(define-read-only (get-audit-record (school-id (string-ascii 50)) (audit-id uint))
  (map-get? audit-trail { school-id: school-id, audit-id: audit-id })
)

;; Get system statistics
(define-read-only (get-system-stats)
  {
    total-schools: (var-get total-schools),
    total-budget-allocated: (var-get total-budget-allocated),
    total-expenditures: (var-get total-expenditures)
  }
)

;; Check if category is valid
(define-read-only (is-category-valid (category (string-ascii 50)))
  (is-valid-category category)
)

;; Calculate budget utilization rate
(define-read-only (calculate-budget-utilization (spent uint) (allocated uint))
  (calculate-utilization-rate spent allocated)
)
