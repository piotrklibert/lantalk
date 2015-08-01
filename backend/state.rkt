#lang racket
(require racket/fasl)
(require rackjure/threading)

(provide
 start-backup-thread!
 add-message!
 get-messages
 debug-enabled?)


(define debug-enabled? (make-parameter #t))


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

(define (start-backup-thread!)
  (displayln "asdasd")
  (thread
   (λ ()
     (let loop ()
       (call-with-output-file "/home/cji/omg.log"
         #:exists 'replace
         (λ (out) (s-exp->fasl messages out)))
       (sleep 10)
       (loop)))))
