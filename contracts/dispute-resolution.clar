;; Dispute Resolution Contract

(define-map disputes
  { market-id: uint }
  {
    disputer: principal,
    reason: (string-utf8 500),
    status: (string-ascii 20),
    resolution: (optional (string-utf8 500))
  }
)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_DISPUTED (err u409))

(define-public (file-dispute (market-id uint) (reason (string-utf8 500)))
  (begin
    (asserts! (is-none (map-get? disputes { market-id: market-id })) ERR_ALREADY_DISPUTED)
    (map-set disputes
      { market-id: market-id }
      {
        disputer: tx-sender,
        reason: reason,
        status: "pending",
        resolution: none
      }
    )
    (ok true)
  )
)

(define-public (resolve-dispute (market-id uint) (resolution (string-utf8 500)))
  (let
    ((dispute (unwrap! (map-get? disputes { market-id: market-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set disputes
      { market-id: market-id }
      (merge dispute { status: "resolved", resolution: (some resolution) })
    )
    (ok true)
  )
)

(define-read-only (get-dispute (market-id uint))
  (map-get? disputes { market-id: market-id })
)

