#lang racket

(require "./helpers.rkt")
(require "./state.rkt")

(provide check-messages)


(define (check-messages req)
  ;; The client just connected so we need to send him all messages to initialize
  ;; its state. (NOTE: this is thread-safe as it's just a read and the data is
  ;; immutable (and in a box))
  (send-resp! url
    (make-json-response (get-messages) url))

  ;; Then we loop endlessly, polling for changes in messages. When a change is
  ;; detected, we send the new list of messages to the client. We also make the
  ;; client reconnect once every 30 seconds, because of some weird "security"
  ;; features in Chrome.
  (let loop ([local-messages (get-messages)])

    (define new-messages null)
    (define time-elapsed 0)
    (define sleep-time 0.2)

    (let inner-loop ()
      ;; A simple spin-lock of a kind. This should be rewritten to use some
      ;; kind of event bus/queue.
      (sleep sleep-time)
      (set! time-elapsed (+ time-elapsed sleep-time)) ; not good! move to rec call

      (if (or (> time-elapsed 30)       ; there are some timeouts in FF and
                                        ; Chrome for XHR connections, we need to
                                        ; close ours before that happens
              (not (equal? local-messages (get-messages))))

          ;; then
          (begin
            (when (debug-enabled?) (pretty-display req)) ; should be a logger call instead
            (set! new-messages (get-messages)))

          ;; else
          (inner-loop)))

    (send-resp! url (make-json-response new-messages url))
    (loop new-messages)))
