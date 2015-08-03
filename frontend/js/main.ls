require! moment
require! {
    "prelude-ls" : {flip, map, filter}
    "ractive"    : Ractive
    "q"          : Q
    "qajax"      : qx
    "URIjs"      : U
}

qx = require \qajax
bacon = require \baconjs
qxJSON = -> qx(it).then(qx.toJSON)

{is_focused} = require "./focus.ls"
{rand-nick} = require "./helpers.ls"
{blink, blink-forever} = require "./blink.ls"

{meta_checker, simple_checker} = require "./checkers.ls"


make-ractive = (model) ->
    new Ractive {
        el: '.main',
        magic: true,
        template: '#tmpl',
        data: model
    }
reload-page = ->
    # refresh current page as if a user hit F5
    window.location = window.location

main =  ->
    params = U! |> (.query!) |> U.parseQuery

    model =
        nick: params["nick"] ? rand-nick!
        debug: params["debug"] ? true
        silent: false
        is_focused: true
        items: [
            # a single item is an object with these properties:
            # value -> any value, depending on context
            # url -> url pointing to the first step of the rest of current transaction
            # info -> optional, an obj with a "status" field
            #
            # Right now only one type of values is provided and it's an object,
            # with following attributes:
            #
            # nick
            # time
            # text
        ]
        input: ""
        modified: false


    window.view = view = make-ractive(model)

    make-model-props = (view, m) ->
        ret = {}
        for let k, v of m
            prop = bacon.from-binder (callback) ->
                view.observe k, callback
            ret[k] = prop.to-property()
        ret

    window.props = make-model-props(view, model)

    #
    # STREAMS
    #

    modifications = bacon.from-binder (out) ->
        meta_checker(simple_checker out)({url: "/modified"})

    messages = bacon.from-binder (out) ->
        meta_checker(simple_checker out)({url: "/post"})


    timer = bacon.interval 30 * 60 * 1000ms, true
    # reload page when something changes or every 30 minutes, whatever is first
    modifications
        .filter ".value"
        .merge timer
        .onValue reload-page


    fresh-messages = messages
        .filter (msgs) -> msgs.value.length != model.items.length

    fresh-messages
        ..filter -> not model.is_focused and not model.silent
            .onValue (data) ->
                notify data.value[*-1], \normal
        ..filter -> model.debug
            .onValue ->
                console.log it.value, model.is_focused, model.debug, model.silent



    messages.onValue ({value}) -> model.items = value
    messages.onValue ->
        $(".msg-board").scrollTo("max")

    messages.onError blink-forever

    is_focused.onValue (model.is_focused =)

    enter-pressed = -> it.original.which == 13
    input-keypresses = bacon.from-view-event view, "maybeEnter"

    enter-presses = input-keypresses.filter enter-pressed

    explicit-sends = (bacon.from-view-event view, "send")

    enter-presses.merge(explicit-sends)
        .onValue handle-send


    # TODO: make a pipeline of transformations instead of cramming them all into
    # `handle-send`
    function handle-send(ev)
        inp = model.input = model.input.replace("\n", "")
        return if inp.length == 0

        # make links/urls clickable by wrapping them with an <a> element
        inp = inp.replace(/https?:\/\/([^ ]*)/,
                          (m, url) -> "<a href='#m' target=_blank>#url</a>")

        model.input = ""

        $.ajax {
            method: "POST",
            url: "/post",
            data: JSON.stringify {
                text: inp
                nick: model.nick
                time: moment().format("h:mm:ss")
            }
        }
        inp

    blink!



notify = (msg, mode=\silent) ->
    if mode == \silent
        console.log  "#{msg.nick} says: #{msg.text}"
        return

    else
        Notification.requestPermission()
        n = new Notification "#{msg.nick} says:", {body: msg.text}
        audio = new Audio("beep.mp3")
        audio.play()




main!
