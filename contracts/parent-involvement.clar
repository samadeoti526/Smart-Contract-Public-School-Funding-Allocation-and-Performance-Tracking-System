;; Parent Involvement Tracking Contract
;; Tracks parent participation in school activities and engagement

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-PARENT-EXISTS (err u501))
(define-constant ERR-PARENT-NOT-FOUND (err u502))
(define-constant ERR-INVALID-INPUT (err u503))
(define-constant ERR-ACTIVITY-NOT-FOUND (err u504))
(define-constant ERR-INVALID-HOURS (err u505))

;; Engagement thresholds
(define-constant HIGH-ENGAGEMENT-THRESHOLD u20)
(define-constant MODERATE-ENGAGEMENT-THRESHOLD u10)

;; Activity types
(define-constant ACTIVITY-VOLUNTEER "volunteer")
(define-constant ACTIVITY-MEETING "meeting")
(define-constant ACTIVITY-EVENT "event")
(define-constant ACTIVITY-COMMUNICATION "communication")
(define-constant ACTIVITY-FUNDRAISING "fundraising")

;; Data Variables
(define-data-var total-parents uint u0)
(define-data-var total-activities uint u0)
(define-data-var total-volunteer-hours uint u0)

;; Data Maps
(define-map parents
  { parent-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    student-ids: (list 5 uint),
    school-id: (string-ascii 50),
    registration-date: uint,
    active: bool,
    total-hours: uint,
    engagement-level: (string-ascii 20)
  }
)

(define-map activities
  { activity-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 200),
    activity-type: (string-ascii 50),
    school-id: (string-ascii 50),
    date: uint,
    duration-hours: uint,
    max-participants: uint,
    current-participants: uint,
    organizer: (string-ascii 50)
  }
)

(define-map participation
  { parent-id: (string-ascii 50), activity-id: uint }
  {
    participation-date: uint,
    hours-contributed: uint,
    role: (string-ascii 50),
    feedback-rating: uint,
    notes: (string-ascii 200)
  }
)

(define-map communication-log
  { parent-id: (string-ascii 50), communication-id: uint }
  {
    communication-type: (string-ascii 50),
    teacher-id: (string-ascii 50),
    subject: (string-ascii 100),
    date: uint,
    initiated-by: (string-ascii 20),
    follow-up-needed: bool
  }
)

(define-map engagement-metrics
  { parent-id: (string-ascii 50), period: uint }
  {
    activities-participated: uint,
    total-hours: uint,
    communication-frequency: uint,
    engagement-score: uint,
    recognition-earned: bool
  }
)

;; Private Functions
(define-private (is-valid-activity-type (activity-type (string-ascii 50)))
  (or (is-eq activity-type ACTIVITY-VOLUNTEER)
      (or (is-eq activity-type ACTIVITY-MEETING)
          (or (is-eq activity-type ACTIVITY-EVENT)
              (or (is-eq activity-type ACTIVITY-COMMUNICATION)
                  (is-eq activity-type ACTIVITY-FUNDRAISING)))))
)

(define-private (calculate-engagement-level (total-hours uint))
  (if (>= total-hours HIGH-ENGAGEMENT-THRESHOLD)
    "high"
    (if (>= total-hours MODERATE-ENGAGEMENT-THRESHOLD)
      "moderate"
      "low"
    )
  )
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

;; Public Functions

;; Register a parent
(define-public (register-parent (parent-id (string-ascii 50)) (name (string-ascii 100))
                               (email (string-ascii 100)) (phone (string-ascii 20))
                               (student-ids (list 5 uint)) (school-id (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len parent-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? parents { parent-id: parent-id })) ERR-PARENT-EXISTS)

    (map-set parents
      { parent-id: parent-id }
      {
        name: name,
        email: email,
        phone: phone,
        student-ids: student-ids,
        school-id: school-id,
        registration-date: block-height,
        active: true,
        total-hours: u0,
        engagement-level: "low"
      }
    )

    (var-set total-parents (+ (var-get total-parents) u1))
    (ok true)
  )
)

;; Create a new activity
(define-public (create-activity (activity-id uint) (name (string-ascii 100)) (description (string-ascii 200))
                               (activity-type (string-ascii 50)) (school-id (string-ascii 50))
                               (duration-hours uint) (max-participants uint) (organizer (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> activity-id u0) ERR-INVALID-INPUT)
    (asserts! (is-valid-activity-type activity-type) ERR-INVALID-INPUT)
    (asserts! (> duration-hours u0) ERR-INVALID-HOURS)

    (map-set activities
      { activity-id: activity-id }
      {
        name: name,
        description: description,
        activity-type: activity-type,
        school-id: school-id,
        date: block-height,
        duration-hours: duration-hours,
        max-participants: max-participants,
        current-participants: u0,
        organizer: organizer
      }
    )

    (var-set total-activities (+ (var-get total-activities) u1))
    (ok true)
  )
)

;; Record parent participation in an activity
(define-public (record-participation (parent-id (string-ascii 50)) (activity-id uint)
                                    (hours-contributed uint) (role (string-ascii 50))
                                    (feedback-rating uint) (notes (string-ascii 200)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? parents { parent-id: parent-id })) ERR-PARENT-NOT-FOUND)
    (asserts! (is-some (map-get? activities { activity-id: activity-id })) ERR-ACTIVITY-NOT-FOUND)
    (asserts! (> hours-contributed u0) ERR-INVALID-HOURS)
    (asserts! (is-valid-rating feedback-rating) ERR-INVALID-INPUT)

    ;; Record participation
    (map-set participation
      { parent-id: parent-id, activity-id: activity-id }
      {
        participation-date: block-height,
        hours-contributed: hours-contributed,
        role: role,
        feedback-rating: feedback-rating,
        notes: notes
      }
    )

    ;; Update parent's total hours and engagement level
    (match (map-get? parents { parent-id: parent-id })
      parent-data
      (let
        (
          (new-total-hours (+ (get total-hours parent-data) hours-contributed))
          (new-engagement-level (calculate-engagement-level new-total-hours))
        )
        (map-set parents
          { parent-id: parent-id }
          (merge parent-data {
            total-hours: new-total-hours,
            engagement-level: new-engagement-level
          })
        )
      )
      false
    )

    ;; Update activity participant count
    (match (map-get? activities { activity-id: activity-id })
      activity-data
      (map-set activities
        { activity-id: activity-id }
        (merge activity-data {
          current-participants: (+ (get current-participants activity-data) u1)
        })
      )
      false
    )

    (var-set total-volunteer-hours (+ (var-get total-volunteer-hours) hours-contributed))
    (ok true)
  )
)

;; Log parent-teacher communication
(define-public (log-communication (parent-id (string-ascii 50)) (communication-id uint)
                                 (communication-type (string-ascii 50)) (teacher-id (string-ascii 50))
                                 (subject (string-ascii 100)) (initiated-by (string-ascii 20))
                                 (follow-up-needed bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? parents { parent-id: parent-id })) ERR-PARENT-NOT-FOUND)
    (asserts! (> (len communication-type) u0) ERR-INVALID-INPUT)

    (map-set communication-log
      { parent-id: parent-id, communication-id: communication-id }
      {
        communication-type: communication-type,
        teacher-id: teacher-id,
        subject: subject,
        date: block-height,
        initiated-by: initiated-by,
        follow-up-needed: follow-up-needed
      }
    )

    (ok true)
  )
)

;; Calculate and record engagement metrics for a period
(define-public (record-engagement-metrics (parent-id (string-ascii 50)) (period uint)
                                         (activities-participated uint) (communication-frequency uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? parents { parent-id: parent-id })) ERR-PARENT-NOT-FOUND)

    (match (map-get? parents { parent-id: parent-id })
      parent-data
      (let
        (
          (engagement-score (+ (* activities-participated u5) (* communication-frequency u2) (/ (get total-hours parent-data) u2)))
          (recognition-earned (>= engagement-score u50))
        )
        (map-set engagement-metrics
          { parent-id: parent-id, period: period }
          {
            activities-participated: activities-participated,
            total-hours: (get total-hours parent-data),
            communication-frequency: communication-frequency,
            engagement-score: engagement-score,
            recognition-earned: recognition-earned
          }
        )

        (ok engagement-score)
      )
      ERR-PARENT-NOT-FOUND
    )
  )
)

;; Update parent status
(define-public (update-parent-status (parent-id (string-ascii 50)) (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (match (map-get? parents { parent-id: parent-id })
      parent-data
      (begin
        (map-set parents
          { parent-id: parent-id }
          (merge parent-data { active: active })
        )
        (ok true)
      )
      ERR-PARENT-NOT-FOUND
    )
  )
)

;; Read-only Functions

;; Get parent information
(define-read-only (get-parent (parent-id (string-ascii 50)))
  (map-get? parents { parent-id: parent-id })
)

;; Get activity details
(define-read-only (get-activity (activity-id uint))
  (map-get? activities { activity-id: activity-id })
)

;; Get participation record
(define-read-only (get-participation (parent-id (string-ascii 50)) (activity-id uint))
  (map-get? participation { parent-id: parent-id, activity-id: activity-id })
)

;; Get communication log entry
(define-read-only (get-communication (parent-id (string-ascii 50)) (communication-id uint))
  (map-get? communication-log { parent-id: parent-id, communication-id: communication-id })
)

;; Get engagement metrics
(define-read-only (get-engagement-metrics (parent-id (string-ascii 50)) (period uint))
  (map-get? engagement-metrics { parent-id: parent-id, period: period })
)

;; Get system statistics
(define-read-only (get-system-stats)
  {
    total-parents: (var-get total-parents),
    total-activities: (var-get total-activities),
    total-volunteer-hours: (var-get total-volunteer-hours)
  }
)

;; Calculate engagement level for hours
(define-read-only (get-engagement-level-for-hours (hours uint))
  (calculate-engagement-level hours)
)

;; Check if activity type is valid
(define-read-only (is-activity-type-valid (activity-type (string-ascii 50)))
  (is-valid-activity-type activity-type)
)
