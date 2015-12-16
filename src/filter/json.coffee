
alight.filters.json =
    watchMode: 'deep'
    onChange: (value) ->
        @.setValue JSON.stringify alight.utils.clone(value), null, 4
