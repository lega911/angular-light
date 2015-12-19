
alight.filters.json = class JsonFilter
    watchMode: 'deep'
    onChange: (value) ->
        @.setValue JSON.stringify alight.utils.clone(value), null, 4
