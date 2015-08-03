###
### A bacon.js-compatible EventEmitters, or rather EventEmitters builders.
###

q = require \q
qx = require \qajax
bacon = require \baconjs
qxJSON = -> qx(it).then(qx.toJSON)

# config :: {url: <string>}
# checker :: (data -> config -> config)
# simple_checker :: (data -> unit) -> checker
simple_checker = (callback) ->
    (data, config) ->
        callback(data)
        config.url = data.url
        config


retry = (url, base ? url) ->
    tries-count = 0
    res = q.defer()

    _inner = (url) ->
        qxJSON(url)
            .then res~resolve
            .fail (reason) ->
                tries-count := tries-count + 1
                if tries-count < 5
                    setTimeout (-> _inner(base)), 5000
                else
                    res.reject(reason)
    _inner(url)
    res.promise



# meta_checker :: string -> checker -> (config -> promise)
meta_checker = (callback) ->
    # _checker is going to be called many times with different urls, but it
    # should remember its first url as a "base" for use with `retry`
    original-url = null

    _checker = ({url}) ->
        unless original-url
            original-url := url
        unless url
            return callback(new bacon.Error("No URL provided!"))

        retry(url, original-url)
            .fail ->
                callback(new bacon.Error("The server died"))
            .then (callback _, config)
            .then _checker      # connect again and wait for more data



exports.meta_checker = meta_checker
exports.simple_checker = simple_checker
