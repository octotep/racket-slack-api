#lang setup/infotab

(define name "slack-api")
(define blurb
  (list
   `(p "Racket bindings for the "
       (a ((href "https://slack.com/")) "Slack")
       "Web and Real-Time Messaging APIs")))
(define homepage "https://github.com/octotep/racket-slack-api")
(define primary-file "main.rkt")
(define categories '(api http))

(define deps '("base" "rfc6455"))
