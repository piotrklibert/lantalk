require! {
    "baconjs": {from-event}
}

focus = from-event(window, "focus")
    .map(true)
blur = from-event(window, "blur")
    .map(false)

is_focused = focus.merge(blur)

current-tab-visible = let
    eventKey = undefined
    keys =
        hidden: 'visibilitychange'
        webkitHidden: 'webkitvisibilitychange'
        mozHidden: 'mozvisibilitychange'
        msHidden: 'msvisibilitychange'

    for stateKey, stateFunc of keys
        if stateKey of document
            eventKey = stateFunc
            break

    ->
        | !!it => document.addEventListener eventKey, it
        | otherwise => !document[stateKey]


exports.current-tab-visible = current-tab-visible
exports.is_focused = is_focused
