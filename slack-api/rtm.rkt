#lang racket

(provide rtm-start)

(require "webapi.rkt")
(require net/rfc6455)
(require net/url)
(require json)

(define current-connection (make-parameter null))

; Starts a websocket connection to the slack Real-Time Messaging API
(define (rtm-start apikey)
  (let* ([result (slack-rtm-start apikey)]
         [wsurl  (hash-ref result 'url)])
    (ws-connect (string->url wsurl))))

; Returns a jsexpr from the rtm websocket
(define (rtm-read rtm-conn)
  (string->jsexpr (ws-recv rtm-conn)))

; Sends a jsexpr to the rtm websocket
(define (rtm-send! rtm-conn)
  (ws-send! rtm-conn (jsexpr->string json)))

; Closes a rtm websocket
(define (rtm-close! rtm-conn)
  (ws-close! rtm-conn))

