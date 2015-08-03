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
 parse-request
 make-json-response
 comp<-
 comp->
 format-response-dict)

(define comp<- compose)
(define comp-> (λ args
                 (for/fold ([val (car args)])
                           ([a (cdr args)])
                   (comp<- a val))))

;; resp! :: any/c -> response?
;; Convert something to its string representation. Wrap the string with a
;; response structure and return it.
(define (resp! val)
  (response/output
   (lambda (output)
     (display val output))))

;; send-resp!
;; ex:
;; (send-resp! url
;;   "something"
;;   'something)
;; Will return a result of body block, which needs to be a response instance,
;; to the client and will suspend execution until the next connection from client.
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

(define jsresp!
  (comp-> jsexpr->bytes resp!))

(define parse-request
  (comp-> request-post-data/raw         ; get data from request struct
          bytes->string/utf-8           ; convert data to unicode string
          string->jsexpr))              ; parse contents of the string as JSON

(define make-json-response
  (comp<- jsexpr->bytes format-response-dict))


(define-syntax-rule (with-semaphore sem . body)
  (call-with-semaphore sem (λ () . body)))
