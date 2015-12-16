
alight.filters.generator =
    watchMode: 'simple'
    init: ->
        @.list = []
    onChange: (size) ->
        if @.list.length >= size
            @.list.length = size
        else
            while @.list.length < size
                @.list.push {}
        @.setValue @.list
