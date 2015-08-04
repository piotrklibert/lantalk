#lang racket
(require racket/fasl)
(require srfi/26)
(require rackjure/threading)

(provide
 start-backup-thread!
 add-message!
 get-messages
 debug-enabled?)


(define debug-enabled? (make-parameter #t))


;; WARNING: STATE!

(define messages-lock (make-semaphore 1)) ; not used yet

(define (load-messages)
  (let ([path "/home/cji/omg.log"])
    (if (file-exists? path)
        (call-with-input-file path fasl->s-exp)
        (box (list)))))


(define messages (box (list)))



(define (add-message! msg-data)
  (let*
      ([msgs-list (unbox messages)]
       [new-msgs (cons msg-data msgs-list)])
    ;; (pretty-display msg-data)
    ;; (displayln (~a msgs-list "\n" new-msgs "\n" messages "imm? " (immutable? messages)))
    (match (box-cas! messages msgs-list new-msgs)
      [#f (add-message! msg-data)]
      [#t #t])))

(define (get-messages) (messages . ~> . unbox reverse))

(define (start-backup-thread!)
  (thread
   (λ ()
     (let loop ()
       (call-with-output-file "/home/cji/omg.log"
         #:exists 'replace

         (cut s-exp->fasl messages <>))
       (sleep 10)
       (loop)))))
