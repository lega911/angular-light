(function(){

/*

alight.createComponent('rating', (scope, element, env) => {
  return {
    template,
    templateId,
    templateUrl,
    props,
    onStart,
    onDestroy,
    api
  };
})

<rating :rating="rating" :max="max" @change="rating=$event.value"></rating>

*/

  const f$ = alight.f$;

  function makeWatch({listener, childCD, name, parentName, parentCD}) {
    let fn;
    let watchOption = {};
    if(listener) {
      if(f$.isFunction(listener)) {
        fn = listener;
      } else {
        fn = listener.onChange;
        if(listener === 'copy' || listener.watchMode === 'copy') {
          if(fn) fn(parentName)
          else childCD.scope[name] = parentName;
          return
        }
        if(listener === 'array' || listener.watchMode === 'array') watchOption.isArray = true;
        if(listener === 'deep' || listener.watchMode === 'deep') watchOption.deep = true;
      }
    }
    if(!fn) {
      fn = function(value) {
        childCD.scope[name] = value;
        childCD.scan();
      }
    }
    parentCD.watch(parentName, fn, watchOption);
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
        const parentCD = env.changeDetector.new();
        const childCD = alight.Scope({
          returnChangeDetector: true
        })
        const scope = childCD.scope;

        scope.$sendEvent = function(eventName, value) {
          let event = new CustomEvent(eventName);
          event.value = value;
          event.component = true;
          element.dispatchEvent(event);
        };

        function ChildEnv() {};
        ChildEnv.prototype = env;
        const childEnv = new ChildEnv();
        childEnv.changeDetector = childCD
        childEnv.parentChangeDetector = parentCD;

        try {
          const option = constructor(scope, element, childEnv) || {};
        } catch (e) {
          alight.exceptionHandler(e, 'Error in component <' + attrName + '>: ', {
            element: element,
            scope: scope,
            cd: childCD
          });
          return;
        }

        if(option.onStart) {
          childCD.watch('$finishBinding', option.onStart);
        }

        // bind props
        parentDestroyed = false;
        parentCD.watch('$destroy', () => {
          parentDestroyed = true;
          childCD.destroy();
        })

        childCD.watch('$destroy', () => {
          if(option.onDestroy) option.onDestroy();
          if(!parentDestroyed) parentCD.destroy();  // child of parentCD
        })

        // option api
        let readyProps = {};
        if(option.api) {
          readyProps[':api'] = true
          let propValue = env.takeAttr(':api');
          if(propValue) parentCD.locals[propValue] = option.api;
        }

        // option props
        if(option.props) {
          for(var key in option.props) {
            let propName = ':' + key;
            let propValue = env.takeAttr(propName);
            let listener = option.props[key];
            readyProps[propName] = true;
            if(!propValue) continue;
            makeWatch({childCD, listener, name: key, parentName: propValue, parentCD});
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
          
          makeWatch({childCD, name, parentName: propValue, parentCD});
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
          alight.bind(childCD, element, {skip: true});
        }
      }
    }
  }

})();
