#lang racket
(require rackjure/threading)

(provide
 add-message!
 get-messages
 debug-enabled?)


(define debug-enabled? (make-parameter #f))


;; GLOBAL STATE
(define messages-lock (make-semaphore 1))
(define messages (box null))

(define (format-messages [msgs 'current])
  (when (equal? msgs 'current)
    (set! msgs (unbox messages)))
  (reverse msgs))



(define (add-message! msg-data)
  (let*
      ([msgs-list (unbox messages)]
       [new-msgs (cons msg-data msgs-list)])
    (match (box-cas! messages msgs-list new-msgs)
      [#f (add-message! msg-data)]
      [#t #t])))

(define (get-messages) (messages . ~> . unbox reverse))
