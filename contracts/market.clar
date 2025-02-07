;; Market Contract

(define-map markets
  { market-id: uint }
  {
    creator: principal,
    description: (string-utf8 500),
    options: (list 10 (string-utf8 100)),
    resolution-time: uint,
    total-stake: uint,
    resolved: bool,
    winning-option: (optional uint)
  }
)

(define-map market-stakes
  { market-id: uint, option: uint }
  { total-stake: uint }
)

(define-map user-stakes
  { market-id: uint, user: principal, option: uint }
  { amount: uint }
)

(define-data-var market-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_OPTION (err u400))
(define-constant ERR_MARKET_RESOLVED (err u403))
(define-constant ERR_MARKET_NOT_RESOLVED (err u405))

(define-public (create-market (description (string-utf8 500)) (options (list 10 (string-utf8 100))) (resolution-time uint))
  (let
    ((new-market-id (+ (var-get market-nonce) u1)))
    (asserts! (> (len options) u0) ERR_INVALID_OPTION)
    (map-set markets
      { market-id: new-market-id }
      {
        creator: tx-sender,
        description: description,
        options: options,
        resolution-time: resolution-time,
        total-stake: u0,
        resolved: false,
        winning-option: none
      }
    )
    (var-set market-nonce new-market-id)
    (ok new-market-id)
  )
)

(define-public (stake (market-id uint) (option uint) (amount uint))
  (let
    ((market (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND))
     (user-stake (default-to { amount: u0 } (map-get? user-stakes { market-id: market-id, user: tx-sender, option: option })))
     (market-stake (default-to { total-stake: u0 } (map-get? market-stakes { market-id: market-id, option: option }))))
    (asserts! (not (get resolved market)) ERR_MARKET_RESOLVED)
    (asserts! (< option (len (get options market))) ERR_INVALID_OPTION)
    (map-set user-stakes
      { market-id: market-id, user: tx-sender, option: option }
      { amount: (+ (get amount user-stake) amount) }
    )
    (map-set market-stakes
      { market-id: market-id, option: option }
      { total-stake: (+ (get total-stake market-stake) amount) }
    )
    (map-set markets
      { market-id: market-id }
      (merge market { total-stake: (+ (get total-stake market) amount) })
    )
    (ok true)
  )
)

(define-public (resolve-market (market-id uint) (winning-option uint))
  (let
    ((market (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (get resolved market)) ERR_MARKET_RESOLVED)
    (asserts! (>= block-height (get resolution-time market)) ERR_UNAUTHORIZED)
    (asserts! (< winning-option (len (get options market))) ERR_INVALID_OPTION)
    (map-set markets
      { market-id: market-id }
      (merge market { resolved: true, winning-option: (some winning-option) })
    )
    (ok true)
  )
)

(define-public (claim-winnings (market-id uint))
  (let
    ((market (unwrap! (map-get? markets { market-id: market-id }) ERR_NOT_FOUND))
     (winning-option (unwrap! (get winning-option market) ERR_MARKET_NOT_RESOLVED))
     (user-stake (unwrap! (map-get? user-stakes { market-id: market-id, user: tx-sender, option: winning-option }) ERR_NOT_FOUND))
     (market-stake (unwrap! (map-get? market-stakes { market-id: market-id, option: winning-option }) ERR_NOT_FOUND)))
    (asserts! (get resolved market) ERR_MARKET_NOT_RESOLVED)
    (let
      ((winnings (/ (* (get amount user-stake) (get total-stake market)) (get total-stake market-stake))))
      (map-delete user-stakes { market-id: market-id, user: tx-sender, option: winning-option })
      (ok winnings)
    )
  )
)

(define-read-only (get-market (market-id uint))
  (map-get? markets { market-id: market-id })
)

(define-read-only (get-market-stake (market-id uint) (option uint))
  (map-get? market-stakes { market-id: market-id, option: option })
)

(define-read-only (get-user-stake (market-id uint) (user principal) (option uint))
  (map-get? user-stakes { market-id: market-id, user: user, option: option })
)
