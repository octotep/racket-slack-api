#lang racket

(provide slack-rtm-start)
(provide slack-api-test)
(provide slack-channels-archive slack-channels-create slack-channels-history
         slack-channels-info slack-channels-invite slack-channels-join
         slack-channels-kick slack-channels-leave slack-channels-list
         slack-channels-mark slack-channels-rename slack-channels-setPurpose
         slack-channels-setTopic slack-channels-unarchive)
(provide slack-chat-delete slack-chat-postMessage slack-chat-update)
(provide slack-emoji-list)
(provide slack-files-delete slack-files-info slack-files-list slack-files-upload)
(provide slack-groups-archive slack-groups-close slack-groups-create
         slack-groups-createChild slack-groups-history slack-groups-info
         slack-groups-invite slack-groups-kick slack-groups-leave
         slack-groups-list slack-groups-mark slack-groups-open
         slack-groups-rename slack-groups-setPurpose slack-groups-setTopic
         slack-groups-unarchive)
(provide slack-im-close slack-im-history slack-im-list slack-im-mark
         slack-im-open)
(provide slack-mpim-close slack-mpim-history slack-mpim-list slack-mpim-mark
         slack-mpim-open)
(provide slack-oauth-access)
(provide slack-pins-add slack-pins-list slack-pins-remove)
(provide slack-reactions-add slack-reactions-get slack-reactions-list
         slack-reactions-remove) (provide slack-rtm-start)
(provide slack-search-all slack-search-files slack-search-messages)
(provide slack-stars-add slack-stars-list slack-stars-remove)
(provide slack-team-accessLogs slack-team-info slack-team-integrationLogs)
(provide slack-usergroups-create slack-usergroups-disable
         slack-usergroups-enable slack-usergroups-list slack-usergroups-update)
(provide slack-usergroups-users-list slack-usergroups-users-update)
(provide slack-users-getPresence slack-users-info slack-users-list
         slack-users-setActive slack-users-setPresence)


(require json)
(require net/url)
(require net/url-connect)
(require openssl)
(require (for-syntax syntax/parse))
(require (for-syntax racket/syntax))
(require (for-syntax racket))

;; Set up the current-https-protocol to allow secured and verified https
;; connections
(current-https-protocol (ssl-make-client-context))
(ssl-set-verify! (current-https-protocol) #t)
(ssl-set-verify-hostname! (current-https-protocol) #t)
(ssl-load-default-verify-sources! (current-https-protocol))

;; Define a interleave function for the create-api-func macro
;; It combines two lists by alternating them
(begin-for-syntax
  (define (interleave list1 list2)
    (match (list list1 list2)
      [(list (cons x xs) (cons y ys)) (cons x (cons y (interleave xs ys)))]
      [(list '() ys)                  ys]
      [(list xs '())                  xs])))

(define (get-slack-json apimethod params)
  (let* ([url (url "https"
                   #f
                   "slack.com"
                   #f
                   #t
                   (list (path/param "api" '()) (path/param apimethod '()))
                   params
                   #f)])
    (call/input-url url
                    get-pure-port
                    (compose string->jsexpr port->string))))

;; This macro generates a function which will recieve each of the macros arguments
;; It receives them into a list of pairs of the symbol and the value
;; That format is required for the net/url url struct
;; Lastly, it filters out any pairs whose value is not a string or false
(define-syntax (create-params stx)
  (syntax-parse stx
    [(_ params:id ...)
     #'(lambda (params ...)
         (filter (lambda (x) (or (false? (cdr x)) (string? (cdr x))))
                 (list (cons (quote params) params) ...)))]))

;; This macro generates functions to interact with the slack web API
;; It takes a string for the api method name, and two lists - one for
;; required arguments and one for optional arguments
;; The generated function returns the json if the web API call is successful
(define-syntax (create-api-func stx)
 (syntax-parse stx
   [(_ apimethod:str (req:id ...) (opt:id ...))
    (with-syntax* ([(keys ...)   (map (compose string->keyword symbol->string)
                                     (syntax->datum #'(opt ...)))]
                   [(pairs ...)  (map (lambda (x) (list x ''())) (syntax->datum #'(opt ...)))]
                   [(weaved ...) (datum->syntax stx (interleave (syntax->datum #'(keys ...))
                                                                (syntax->datum #'(pairs ...))))])
      #'(lambda (req ... weaved ...)
          (let* ([paramfunc (create-params req ... opt ...)]
                 [params    (paramfunc req ... opt ...)])
            (get-slack-json apimethod params))))]))


;; API methods

(define slack-api-test (create-api-func "api.test" () (error foo)))

(define slack-auth-test (create-api-func "auth.test" (token) ()))

(define slack-channels-archive (create-api-func "channels.archive" (token channel) ()))
(define slack-channels-create (create-api-func "channels.create" (token channel) ()))
(define slack-channels-history (create-api-func "channels.history" (token channel) (latest oldest inclusive count unreads)))
(define slack-channels-info (create-api-func "channels.info" (token channel) ()))
(define slack-channels-invite (create-api-func "channels.invite" (token channel user) ()))
(define slack-channels-join (create-api-func "channels.join" (token name) ()))
(define slack-channels-kick (create-api-func "channels.kick" (token name user) ()))
(define slack-channels-leave (create-api-func "channels.leave" (token name) ()))
(define slack-channels-list (create-api-func "channels.list" (token) (exclude_archived)))
(define slack-channels-mark (create-api-func "channels.mark" (token channel ts) ()))
(define slack-channels-rename (create-api-func "channels.rename" (token channel name) ()))
(define slack-channels-setPurpose (create-api-func "channels.setPurpose" (token channel purpose) ()))
(define slack-channels-setTopic (create-api-func "channels.setTopic" (token channel topic) ()))
(define slack-channels-unarchive (create-api-func "channels.unarchive" (token channel) ()))

(define slack-chat-delete (create-api-func "chat.delete" (token ts channel) ()))
(define slack-chat-postMessage (create-api-func "chat.postMessage" (token channel text) (username as_user parse link_names attachments unfurl_media icon_url icon_emoji)))
(define slack-chat-update (create-api-func "chat.update" (token ts channel text) (attachments parse link_names)))

(define slack-emoji-list (create-api-func "emoji.list" (token) ()))

(define slack-files-delete (create-api-func "files.delete" (token file) ()))
(define slack-files-info (create-api-func "files.info" (token file) (count page)))
(define slack-files-list (create-api-func "files.list" (token) (user ts_from ts_to types count page)))
(define slack-files-upload (create-api-func "files.upload" (token) (file content filetype filename title initial_comment channels)))

(define slack-groups-archive (create-api-func "groups.archive" (token channel) ()))
(define slack-groups-close (create-api-func "groups.close" (token channel) ()))
(define slack-groups-create (create-api-func "groups.create" (token name) ()))
(define slack-groups-createChild (create-api-func "groups.createChild" (token channel) ()))
(define slack-groups-history (create-api-func "groups.history" (token channel) (latest oldest inclusive count unreads)))
(define slack-groups-info (create-api-func "groups.info" (token channel) ()))
(define slack-groups-invite (create-api-func "groups.invite" (token channel user) ()))
(define slack-groups-kick (create-api-func "groups.kick" (token channel user) ()))
(define slack-groups-leave (create-api-func "groups.leave" (token channel) ()))
(define slack-groups-list (create-api-func "groups.list" (token) (exclude_archived)))
(define slack-groups-mark (create-api-func "groups.mark" (token channel ts) ()))
(define slack-groups-open (create-api-func "groups.open" (token channel) ()))
(define slack-groups-rename (create-api-func "groups.rename" (token channel name) ()))
(define slack-groups-setPurpose (create-api-func "groups.setPurpose" (token channel purpose) ()))
(define slack-groups-setTopic (create-api-func "groups.setTopic" (token channel topic) ()))
(define slack-groups-unarchive (create-api-func "groups.unarchive" (token channel) ()))

(define slack-im-close (create-api-func "im.close" (token channel) ()))
(define slack-im-history (create-api-func "im.history" (token channel) (latest oldest inclusive count unreads)))
(define slack-im-list (create-api-func "im.list" (token) ()))
(define slack-im-mark (create-api-func "im.mark" (token channel ts) ()))
(define slack-im-open (create-api-func "im.open" (token user) ()))

(define slack-mpim-close (create-api-func "mpim.close" (token channel) ()))
(define slack-mpim-history (create-api-func "mpim.history" (token channel) (latest oldest inclusive count unreads)))
(define slack-mpim-list (create-api-func "mpim.list" (token) ()))
(define slack-mpim-mark (create-api-func "mpim.mark" (token channel ts) ()))
(define slack-mpim-open (create-api-func "mpim.open" (token users) ()))

(define slack-oauth-access (create-api-func "oauth.access" (client_id client_secret code) (redirect_url)))

(define slack-pins-add (create-api-func "pins.add" (token channel) (file file_comment timestamp)))
(define slack-pins-list (create-api-func "pins.list" (token channel) ()))
(define slack-pins-remove (create-api-func "pins.remove" (token channel) (file file_comment timestamp)))

(define slack-reactions-add (create-api-func "reactions.add" (token name) (file file_comment channel timestamp)))
(define slack-reactions-get (create-api-func "reactions.get" (token) (file file_comment channel timestamp full)))
(define slack-reactions-list (create-api-func "reactions.list" (token) (user full count page)))
(define slack-reactions-remove (create-api-func "reactions.remove" (token name) (file file_comment channel timestamp)))

(define slack-rtm-start (create-api-func "rtm.start" (token) (token_latest no_unreads mpim_aware)))

(define slack-search-all (create-api-func "search.all" (token query) (sort sort_dir highlight count page)))
(define slack-search-files (create-api-func "search.files" (token query) (sort sort_dir highlight count page)))
(define slack-search-messages (create-api-func "search.messages" (token query) (sort sort_dir highlight count page)))

(define slack-stars-add (create-api-func "stars.add" (token) (file file_comment channel timestamp)))
(define slack-stars-list (create-api-func "stars.list" (token) (user count page)))
(define slack-stars-remove (create-api-func "stars.remove" (token) (file file_comment channel timestamp)))

(define slack-team-accessLogs (create-api-func "team.accessLogs" (token) (count page)))
(define slack-team-info (create-api-func "team.info" (token) ()))
(define slack-team-integrationLogs (create-api-func "team.integrationLogs" (token) (service_id app_id user change_type count page)))

(define slack-usergroups-create (create-api-func "usergroups.create" (token name) (handle description channels include_count)))
(define slack-usergroups-disable (create-api-func "usergroups.disable" (token usergroup) (include_count)))
(define slack-usergroups-enable (create-api-func "usergroups.enable" (token usergroup) (include_count)))
(define slack-usergroups-list (create-api-func "usergroups.list" (token) (include_disabled include_count include_users)))
(define slack-usergroups-update (create-api-func "usergroups.update" (token usergroup) (name handle description channels include_count)))

(define slack-usergroups-users-list (create-api-func "usergroups.users.list" (token usergroup) (include_disabled)))
(define slack-usergroups-users-update (create-api-func "usergroups.users.update" (token usergroup) (users include_count)))

(define slack-users-getPresence (create-api-func "users.getPresence" (token user) ()))
(define slack-users-info (create-api-func "users.info" (token user) ()))
(define slack-users-list (create-api-func "users.list" (token) (presence)))
(define slack-users-setActive (create-api-func "users.setActive" (token) ()))
(define slack-users-setPresence (create-api-func "users.setPresence" (token presence) ()))
