;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-POOL-NOT-FOUND (err u104))
(define-constant ERR-LIQUIDATION-FAILED (err u105))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u106))
(define-constant ERR-INVALID-VOTE (err u107))

;; Data variables
(define-data-var minimum-collateral-ratio uint u150) ;; 150% collateral ratio
(define-data-var platform-fee uint u1) ;; 0.1% fee in basis points
(define-data-var total-liquidity uint u0)
(define-data-var governance-token-name (string-ascii 32) "GOVTOKEN")
(define-data-var proposal-count uint u0)
(define-data-var liquidation-penalty uint u10) ;; 10% penalty
(define-data-var total-staked uint u0)