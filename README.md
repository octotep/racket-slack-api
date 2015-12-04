# Slack API bindings for Racket

*This is a work in progress, and the interface is going to be changed*

This is a set of racket bindings to interact with the Slack API. Right now there are two parts:

1. webapi.rkt - This wraps all the Slack Web RPC calls
2. rtm.rkt - This wraps the Real-Time Messaging API

The Real-Time Messaging API is very underdeveloped and due for some changes
