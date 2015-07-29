#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         racket/contract
         json
         )

(provide
 resp!
 send-resp!
 make-json-response
 comp<-
 comp->
 format-response-dict)

(define comp<- compose)
(define comp-> (λ args
                 (for/fold ([val (car args)])
                           ([a (cdr args)])
                   (comp<- a val))))

(define (resp! val)
  (response/output
   (lambda (output)
     (display val output))))

(define-syntax-rule (send-resp! cont-id . body)
  (send/suspend
   (lambda (cont-id)
     (resp! (begin
              . body)))))



(define (format-response-dict value next)
  (hash
   'value value
   'url next
   'info (hash
          'status "ok")))

(define jsresp! (comp-> jsexpr->bytes resp!))

(define make-json-response
  (comp<-  jsexpr->bytes format-response-dict))


(define-syntax-rule (with-semaphore sem . body)
  (call-with-semaphore sem (λ () . body)))
