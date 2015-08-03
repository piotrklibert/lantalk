bacon = require \baconjs


_rand-letter = ->
    String.from-char-code(
        Math.round(70 + Math.random() * 20) # more or less the alphabet range
    )


exports.rand-nick = ->
    [_rand-letter! for _ to 3 ] .join ""


bacon.from-view-event = (view, event-name)->
    bacon.from-binder (view.on event-name, _)
