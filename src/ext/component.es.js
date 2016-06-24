(function(){

/*

alight.createComponent('rating', (scope, element, env) => {
  return {
    template,
    templateId,
    templateUrl,
    props,
    onStart,
    onDestroy
  };
})

<rating :rating="rating" :max="max" @change="rating=$event.value"></rating>

*/

  const f$ = alight.f$;

  function makeWatch({listener, scope, name, parentName, parentCD}) {
    let fn;
    let watchOption = {};
    if(listener) {
      if(f$.isFunction(listener)) {
        fn = listener;
      } else {
        if(listener.watchMode === 'array') watchOption.isArray = true;
        if(listener.watchMode === 'deep') watchOption.deep = true;
        fn = listener.onChange;
      }
    }
    if(!fn) {
      fn = function(value) {
        scope[name] = value;
        scope.$scan();
      }
    }
    return parentCD.watch(parentName, fn, watchOption)
  }

  alight.createComponent = function(attrName, constructor) {
    let parts = attrName.match(/^(\w+)[\-](.+)$/)
    let ns, name;
    if(parts) {
      ns = parts[1]
      name = parts[2]
    } else {
      ns = '$global'
      name = attrName
    }
    name = name.replace(/(-\w)/g, (m) => {
        return m.substring(1).toUpperCase()
    })

    if(!alight.d[ns]) alight.d[ns] = {};
    alight.d[ns][name] = {
      restrict: 'E',
      stopBinding: true,
      priority: 5,
      init: function(parentScope, element, _value, env) {
        const parentCD = env.changeDetector;
        let scope = alight.Scope()
        parentScope.$watch('$destroy', () => scope.$destroy() )
        scope.$dispatch = function(eventName, value) {
          let event = new CustomEvent(eventName);
          event.value = value;
          element.dispatchEvent(event);
        };
        
        let option = constructor(scope, element, env);

        if(option.onStart) {
          scope.$watch('$finishBinding', option.onStart)
        }

        // bind props
        let watchers = [];
        scope.$watch('$destroy', () => {
          for(let w of watchers) w.stop()
          if(option.onDestroy) option.onDestroy()
        })
        
        // option props
        let readyProps = {};
        if(option.props) {
          for(var key in option.props) {
            let propName = ':' + key;
            let propValue = env.takeAttr(propName);
            let listener = option.props[key];
            readyProps[propName] = true;
            if(!propValue) continue;
            watchers.push(makeWatch({scope, listener, name: key, parentName: propValue, parentCD}));
          }
        }
        
        // element props
        for(let attr of element.attributes) {
          let propName = attr.name;
          if(readyProps[propName]) continue;
          readyProps[propName] = true;
          
          let propValue = attr.value;
          if(!propValue) continue;
          
          let parts = propName.match(/^\:(.*)$/)
          if(!parts) continue;
          let name = parts[1];
          
          watchers.push(makeWatch({scope, name, parentName: propValue, parentCD}));
        }

        // template
        if(option.template) element.innerHTML = option.template;
        if(option.templateId) {
          let templateElement = document.getElementById(option.templateId);
          if(!templateElement) throw 'No template ' + option.templateId;
          element.innerHTML = templateElement.innerHTML;
        }
        if(option.templateUrl) {
          f$.ajax({
            url: option.templateUrl,
            cache: true,
            success: (template) => {
              element.innerHTML = template;
              binding(true);
            },
            error: () => {
              console.error('Template is not loaded',option.templateUrl )
            }
          })
        } else {
          binding();
        }

        function binding(async) {
          alight.bind(scope, element, {skip_top: true});
        }
      }
    }
  }

})();
