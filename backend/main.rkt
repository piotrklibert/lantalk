#lang racket
(require json rackjure/threading)
(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch)


;; GLOBAL STATE
(define *messages* (box null))

(define (add-message! msg-data)
  (let*
      ([msgs-list (unbox *messages*)]
       [new-msgs (cons msg-data msgs-list)])
    (match (box-cas! *messages* msgs-list new-msgs)
      [#f (add-message! msg-data)]
      [#t #t])))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; GLOBAL DEBUG DATA
(define (js-bundle-modification-time)
  (~> "/home/cji/poligon/lanchat/frontend/js/bundle.js"
    string->path
    file-or-directory-modify-seconds))
(define modified-date (js-bundle-modification-time))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (create-response/text content)
  (define headers null)
  (response/full 200 #"OK" (current-seconds)
    TEXT/HTML-MIME-TYPE headers (list content)))

(define (check-modified r)
  (define new-date (js-bundle-modification-time))
  (if (> new-date modified-date)
      (begin
        (set! modified-date new-date)
        #"true")
      #"false"))


;; ENDPOINTS DEFINITIONS
(define (posts-list req)
  (match (request-method req)
    [#"GET" (~> *messages* unbox reverse jsexpr->bytes create-response/text)]
    [#"POST" (begin0
                 (create-response/text #"OK")
               (add-message! (~> req
                               request-post-data/raw
                               bytes->string/utf-8 string->jsexpr)))]))

(define-values (dispatch-function site-url)
  (dispatch-rules
   [("post") #:method (or "get" "post") posts-list]
   [("modified") (compose create-response/text
                          check-modified)]
   [("") (λ (r)
           (redirect-to "/index.html"))]
   ;;[else ....]
   ))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(module+ main
  (serve/servlet dispatch-function
    #:launch-browser? #f
    #:servlet-path "" #:servlet-regexp #rx""
    #:listen-ip "0.0.0.0" #:port 8081
    #:extra-files-paths '("/home/cji/poligon/lanchat/frontend/")
    #:server-root-path "/home/cji/poligon/lanchat/backend/"))
