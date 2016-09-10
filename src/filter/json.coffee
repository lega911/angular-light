
alight.filters.json =
    watchMode: 'deep'
    fn: (value) ->
        JSON.stringify alight.utils.clone(value), null, 4
