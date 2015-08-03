#lang racket

(require xml json
         srfi/26                        ; for cut
         rackjure/threading             ; ~> as threading macro

         web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         web-server/private/servlet)


(require "./state.rkt")                 ; add-message! and get-messages

(require "./messages-endpoint.rkt")     ; check-messages
(require "./modifications-endpoint.rkt"); check-modified

(require "./helpers.rkt")               ; comp->


(define (posts-list req)
  (match (request-method req)
    [#"GET" (check-messages req)]
    [#"POST"
     (begin
       (add-message! (parse-request req))
       (resp! #"OK"))]))


(define-values (dispatch-function site-url)
  (dispatch-rules
   ;; url-re        method (optional)       view
   [("post")     #:method (or "get" "post") posts-list] ; TODO: make a second route for get and post reqs
   [("modified")                           (comp-> check-modified resp!)]
   [("")                                   (λ (r)
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
