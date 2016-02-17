
###
    <select al-select="selected">
      <option al-repeat="item in list" al-option="item">{{item.name}}</option>
      <optgroup label="Linux">
          <option al-repeat="linux in list2" al-option="linux">Linux {{linux.codeName}}</option>
      </optgroup>
    </select>
###

do ->
    if window.Map
        Mapper = ->
            @.idByItem = new Map
            @.itemById = {}
            @.index = 1
            @

        Mapper::acquire = (item) ->
            id = "i#{@.index++}"
            @.idByItem.set item, id
            @.itemById[id] = item
            id

        Mapper::release = (id) ->
            item = @.itemById[id]
            delete @.itemById[id]
            @.idByItem.delete item
            return

        Mapper::replace = (id, item) ->
            old = @.itemById[id]
            @.idByItem.delete old
            @.idByItem.set item, id
            @.itemById[id] = item
            return

        Mapper::getId = (item) ->
            @.idByItem.get item

        Mapper::getItem = (id) ->
            @.itemById[id] or null

    else
        Mapper = ->
            @.itemById =
                'i#null': null
            @

        Mapper::acquire = (item) ->
            if item is null
                return 'i#null'

            if typeof item is 'object'
                id = item.$alite_id
                if not id
                    item.$alite_id = id = alight.utils.getId()
            else
                id = '' + item
            @.itemById[id] = item
            id

        Mapper::release = (id) ->
            delete @.itemById[id]
            return

        Mapper::replace = (id, item) ->
            @.itemById[id] = item
            return

        Mapper::getId = (item) ->
            if item is null
                return 'i#null'
            if typeof item is 'object'
                item.$alite_id
            else
                '' + item

        Mapper::getItem = (id) ->
            @.itemById[id] or null


    alight.d.al.select = (scope, element, key, env) ->
        cd = env.changeDetector.new()  # child CD
        env.stopBinding = true

        cd.$select =
            mapper: mapper = new Mapper

        # child-options were changed
        lastValue = null
        cd.$select.change = ->
            setValueOfElement lastValue

        setValueOfElement = (value) ->
            id = mapper.getId value
            if id
                element.value = id
            else
                element.selectedIndex = -1

        watch = cd.watch key, (value) ->
            lastValue = value
            setValueOfElement value

        alight.bind cd, element,
            skip_attr: env.skippedAttr()

        onChangeDOM = (event) ->
            lastValue = mapper.getItem event.target.value
            cd.setValue key, lastValue
            cd.scan
                skipWatch: watch

        f$.on element, 'input', onChangeDOM
        f$.on element, 'change', onChangeDOM
        cd.watch '$destroy', ->
            f$.off element, 'input', onChangeDOM
            f$.off element, 'change', onChangeDOM

    alight.d.al.option = (scope, element, key, env) ->
        cd = step = env.changeDetector
        for i in [0..4]
            select = step.$select
            if select
                break
            step = step.parent or {}
        if not select
            alight.exceptionHandler '', 'Error in al-option - al-select is not found',
                cd: cd
                scope: cd.scope
                element: element
                value: key
            return

        mapper = select.mapper
        id = null
        cd.watch key, (item) ->
            if id
                if mapper.getId(item) isnt id
                    mapper.release id
                    id = mapper.acquire item
                    element.value = id
                    select.change()
                else
                    mapper.replace id, item
            else
                id = mapper.acquire item
                element.value = id
                select.change()
            return

        cd.watch '$destroy', ->
            mapper.release id
            select.change()
        return
