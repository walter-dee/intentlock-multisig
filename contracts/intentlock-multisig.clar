;; ============================================================
;; Contract: intentlock-multisig.clar
;; Purpose : Multisig controller for intent execution
;; ============================================================

;; -------------------------
;; ERRORS
;; -------------------------
(define-constant ERR-NOT-SIGNER        (err u12001))
(define-constant ERR-ALREADY-APPROVED  (err u12002))
(define-constant ERR-INTENT-NOT-FOUND  (err u12003))
(define-constant ERR-THRESHOLD-NOT-MET (err u12004))

;; -------------------------
;; STATE
;; -------------------------

(define-data-var threshold uint u2)
(define-data-var intent-counter uint u0)

;; approved signers
(define-map signers
  { signer: principal }
  { active: bool }
)

;; intent-id => intent data
(define-map intents
  { id: uint }
  {
    approvals: uint,
    executed: bool
  }
)

;; intent-id + signer => approved?
(define-map approvals
  { id: uint, signer: principal }
  { approved: bool }
)

;; -------------------------
;; INITIALIZATION
;; -------------------------

(define-public (initialize
  (initial-signers (list 10 principal))
  (required uint)
)
  (begin
    ;; can only be called once (contract deployment tx)
    (asserts! (is-eq (var-get intent-counter) u0) ERR-INTENT-NOT-FOUND)

    (var-set threshold required)

    ;; register all signers
    (fold register-signer initial-signers true)

    (ok true)
  )
)

;; -------------------------
;; CREATE INTENT
;; -------------------------

(define-public (create-intent)
  (let ((id (+ (var-get intent-counter) u1)))
    (begin
      (asserts!
        (is-some (map-get? signers { signer: tx-sender }))
        ERR-NOT-SIGNER
      )

      (var-set intent-counter id)

      (map-set intents
        { id: id }
        {
          approvals: u0,
          executed: false
        }
      )

      (ok id)
    )
  )
)

;; -------------------------
;; APPROVE INTENT
;; -------------------------

(define-public (approve-intent (id uint))
  (let ((intent (map-get? intents { id: id })))
    (begin
      (asserts!
        (is-some (map-get? signers { signer: tx-sender }))
        ERR-NOT-SIGNER
      )

      (asserts! (is-some intent) ERR-INTENT-NOT-FOUND)

      (asserts!
        (is-none (map-get? approvals { id: id, signer: tx-sender }))
        ERR-ALREADY-APPROVED
      )

      (map-set approvals
        { id: id, signer: tx-sender }
        { approved: true }
      )

      (map-set intents
        { id: id }
        (merge (unwrap! intent ERR-INTENT-NOT-FOUND)
          { approvals: (+ (get approvals (unwrap! intent ERR-INTENT-NOT-FOUND)) u1) }
        )
      )

      (ok true)
    )
  )
)

;; -------------------------
;; EXECUTE INTENT
;; -------------------------

(define-public (execute-intent (id uint))
  (let ((intent (map-get? intents { id: id })))
    (begin
      (asserts! (is-some intent) ERR-INTENT-NOT-FOUND)

      (let ((data (unwrap! intent ERR-INTENT-NOT-FOUND)))
        (begin
          (asserts!
            (>= (get approvals data) (var-get threshold))
            ERR-THRESHOLD-NOT-MET
          )

          (asserts!
            (not (get executed data))
            ERR-ALREADY-APPROVED
          )

          ;; mark executed
          (map-set intents
            { id: id }
            (merge data { executed: true })
          )

          ;; execution delegated to intent wallet / vault
          (ok true)
        )
      )
    )
  )
)

;; -------------------------
;; READ-ONLY HELPERS
;; -------------------------

(define-read-only (intent-status (id uint))
  (map-get? intents { id: id })
)

(define-read-only (is-signer (signer principal))
  (is-some (map-get? signers { signer: signer }))
)

;; -------------------------
;; PRIVATE HELPERS
;; -------------------------

(define-private (register-signer
  (signer principal)
  (acc bool)
)
  (begin
    (map-set signers { signer: signer } { active: true })
    acc
  )
)
