### Please don't look at this. It's just a sample code I wrote to learn Promises
### API. It's used, but shouldn't be: there's probably a plugin for this
### somewhere.
###
### BTW: it makes background of a page go red and back, either once or forever.
###

require! {
    "prelude-ls" : {flip, map, filter}
    "q"          : Q
    "qajax"      : qx
}

dim-background = (color = "white")->
    d = Q.defer!

    $(".main").animate(
        {backgroundColor: color},
        {duration: 800, complete: -> d.resolve(true)}
        )

    d.promise

lit-background = ->
    d = Q.defer!

    $(".main").animate(
        {backgroundColor: "transparent"},
        {duration: 800, complete: -> d.resolve(true)}
        )

    d.promise


clear-background = ->
    $(".main").attr("style", null)


blink = (color = \white)->
    Q.delay(100)
        .then(dim-background color)
        .then(lit-background)
        .then(clear-background)

blink-forever = ->
    blink "red"
        .then blink-forever


exports.blink = blink

exports.blink-forever = blink-forever
