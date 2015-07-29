#lang racket


(require json rackjure/threading srfi/26)
(require "./helpers.rkt")
(require "./state.rkt")

(provide
 check-modified)

(define (any-updated? a b)
  (not (foldl (λ (a b) (and a b)) #t (map equal? a b))))


(define (mod-time some-file)
  (some-file . ~> . string->path file-or-directory-modify-seconds))
(define (check-times)
  (map mod-time watched-files))


(define watched-files
  (let ([root (cut string-append "/home/cji/poligon/lanchat/" <>)])
    (list (root "frontend/js/bundle.js")
          (root "frontend/index.html")
          (root "backend/main.rkt"))))


(define (check-modified r)
  (if (debug-enabled?)
      (make-json-response #f)
      (let
          ([prev (check-times)])
        (send-resp! url (make-json-response #f url))

        (let loop ([state prev])
          (let ([current  (check-times)])

            (send-resp! url
              (make-json-response (any-updated? state current) url))

            (sleep 2.5)

            (loop current))))))
