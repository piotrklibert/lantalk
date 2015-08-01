#lang racket
(require web-server/private/connection-manager)

(require xml)
(require json)
(require racket/contract)
(require json rackjure/threading srfi/26)
(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         web-server/private/servlet)


(require "./helpers.rkt")
(require "./state.rkt")

(require "./modifications-endpoint.rkt")
(require "./messages-endpoint.rkt")


(define (posts-list req)
  (match (request-method req)
    [#"GET" (check-messages req)]
    [#"POST" (begin
               (add-message! (req . ~> . request-post-data/raw bytes->string/utf-8 string->jsexpr))
               (resp! #"OK"))]))




(define-values (dispatch-function site-url)
  (dispatch-rules
   ;; url-re        (optional method)       view
   [("post")     #:method (or "get" "post") posts-list]
   [("modified")                           (comp-> check-modified resp!)]
   [("") (λ (r)
           (redirect-to "/index.html"))]
   ;;[else ....] - by default it calls the next dispatcher, if there is any
   ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require web-server/managers/lru)

(define (serve)
  (serve/servlet dispatch-function
    #:launch-browser? #f
    #:servlet-path "" #:servlet-regexp #rx""
    #:listen-ip "0.0.0.0" #:port 8081
    #:extra-files-paths '("/home/cji/poligon/lanchat/frontend/")
    #:server-root-path "/home/cji/poligon/lanchat/backend/"))



(define (serve*)
  (thread serve))


(module+ main
  (start-backup-thread!)
  (serve))
