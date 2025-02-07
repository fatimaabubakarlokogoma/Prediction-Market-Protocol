;; Token Contract

(define-fungible-token prediction-market-token)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (ft-transfer? prediction-market-token amount sender recipient)
  )
)

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ft-mint? prediction-market-token amount recipient)
  )
)

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance prediction-market-token account))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply prediction-market-token))
)

