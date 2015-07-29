#lang typed/racket

(require rackjure/threading)

(provide
 add-messages!
 get-messages
 debug-enabled?)


(define debug-enabled? (make-parameter #f))


;; GLOBAL STATE
(define messages-lock (make-semaphore 1))

(: messages (Boxof (Listof Any)))
(define messages (box '()))


(: format-messages (-> (U Symbol (Listof Any)) (Listof Any) ))
(define (format-messages [msgs 'current])
  (reverse (cond
             [(and (symbol? msgs) (equal? msgs 'current)) (unbox messages)]
             [msgs (cast msgs (Listof Any))]
             [else '()])))



;; (define (add-message! msg-data)
;;   (let*
;;       ([msgs-list (unbox messages)]
;;        [new-msgs (cons msg-data msgs-list)])
;;     (match (box-cas! messages msgs-list new-msgs)
;;       [#f (add-message! msg-data)]
;;       [#t #t])))

(define (add-messages! . msgs)
  msgs)

(define (get-messages)
  (messages . ~> . unbox reverse))
