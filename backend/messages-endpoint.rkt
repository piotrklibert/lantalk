#lang racket

(require "./helpers.rkt")
(require "./state.rkt")

(provide check-messages)


(define (check-messages req)
  ;; The client just connected for the first time, so we need to send him all
  ;; messages to initialize its state.
  ;;
  ;; NOTE: this is thread-safe
  (send-resp! url
    (make-json-response (get-messages) url))

  (let loop
      ([local-messages (get-messages)])

    (define new-messages null)
    (define sum 0)

    (let inner-loop ()
      ;; A simple spin-lock of a kind. This should be rewritten to use some
      ;; kind of event bus/queue.
      (sleep 0.5)

      (when (debug-enabled?)
        (displayln
         (format "~a ~a ~a" req sum new-messages)))

      (set! sum (+ sum 0.5))
      (if (or (> sum 30)                ; there are some timeouts in FF and
                                        ; Chrome for XHR connections, we need to
                                        ; close ours before that happens
              (not (equal? local-messages (get-messages))))
          ;; then
          (set! new-messages (get-messages))
          ;; else
          (inner-loop)))

    (send-resp! url (make-json-response new-messages url))
    (loop new-messages)))
