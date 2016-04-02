(function(){

/*

    al-route - define route (can be empty)
    al-route:default - it's activated on undefined url (for 404)
    al-route-out="onOut()" - return true if you want prevent url be changed
    al-on.route-to - event when route is activated, you can use al-ctrl instead of it.
    scope.$route - contains arguments from url

    alight.router = {
        setBase(location.pathname)
        go(link)  // move to link
        subscribe(fn, [flag])  // subscribe on changes url, on 404 page, out-event
        unsubscribe(fn, [flag])
        getCurrentUrl()
        isDefault()  // returns true if it's 404
    }

    TODO:
    // $(window).unload(function(e){
*/

alight.router = (function() {
  let value = document.location.pathname;
  let list = [];
  let nameList = {
    main: list,
    default: [],
    out: [],
    out2: []
  };
  let defaultStatus = false;
  let base = '';
  
  window.onpopstate = function() {
    let path = document.location.pathname.slice(base.length);
    alight.router.go(path, true);
  };

  return {
    setBase: function(n) {
      base = n.match(/^(.*\w+)\/*$/)[1];
    },
    getCurrentUrl: function() {
      return value
    },
    isDefault: function() {
      return defaultStatus
    },
    go: function(url, noPush) {
      if(url === value) return;
      // out
      for(let fn of nameList.out.slice())
        if(fn(url)) {
          // set old url
          if(noPush) history.pushState(null, null, base + value);
          return false;
        }

      // out2
      for(let fn of nameList.out2.slice())
        if(fn(url)) {
          // set old url
          if(noPush) history.pushState(null, null, base + value);
          return false;
        }

      //change url
      if(!noPush) history.pushState(null, null, base + url);
      value = url;
      
      // publish
      let taken = false;
      for(let fn of list.slice())
        if(fn(url)) taken = true;

      // call route:default
      defaultStatus = !taken;
      for(let fn of nameList.default.slice())
        fn(defaultStatus);
      return true;
    },
    subscribe: function(fn, key) {
      nameList[key || 'main'].push(fn);
    },
    unsubscribe: function(fn, key) {
      let l = nameList[key || 'main'];
      let i = l.indexOf(fn);
      if(i>=0) l.splice(i, 1);
    }
  }
})();


class Route {
  constructor() {
    this.routes = [];
  }
  add(url) {
    this.routes.push(routeMatcher(url));
  }
  test(url) {
    for(let route of this.routes) {
      let result = route(url);
      if(result) return result
    }
    return false;
  }
  size() {
    return this.routes.length
  }
};

let f$ = alight.f$;

alight.d.al.route = {
  priority: 1000,
  init: function(scope, baseElement, inputUrl, env) {
    let parentCD = env.changeDetector;
    env.stopBinding = true;
    
    let outCondition = null;
    let $router = {
      result: {
        go: alight.router.go
      },
      setOut: function(fn) {
        outCondition = (url) => {
          if(route.test(url)) return false;
          return fn();
        }
        alight.router.subscribe(outCondition, 'out');
      }
    };
    
    let route = new Route();
    let defaultRoute = env.attrArgument === 'default';
    if(inputUrl) route.add(inputUrl)
    else if(!defaultRoute) {
      inputUrl = '<group>'
      for(let el of baseElement.querySelectorAll('[al-route]')) {
        let url = el.getAttribute('al-route');
        if(!url) continue;
        route.add(url)
      };
      defaultRoute = !!baseElement.querySelector('[al-route\\.default]');
    };
    
    if(defaultRoute) inputUrl += ':default'
    
    let flagUrl = false;
    let flagDefault = false;
  
    if(route.size()) {
      let onChangeUrl = (url) => {
        let result = route.test(url);
        flagUrl = !!result;
        
        if(flagUrl || flagDefault) {
          insertBlock(result);
          return flagUrl;
        } else removeBlock();
        return false;
      }
      alight.router.subscribe(onChangeUrl);
      
      parentCD.watch('$destroy', () => {
        alight.router.unsubscribe(onChangeUrl);
        removeBlock(true);
      });
    }
    
    if(defaultRoute) {
      flagDefault = alight.router.isDefault();
      function onDefault(active) {
        flagDefault = active;
        if(flagUrl || flagDefault) insertBlock(null)
        else removeBlock();
        scope.$scan({late: true});
      }
      alight.router.subscribe(onDefault, 'default')
      parentCD.watch('$destroy', () => {
        alight.router.unsubscribe(onDefault, 'default');
        removeBlock(true);
      });
    }
  
    
    let topElement = document.createComment("route: " + inputUrl);
    f$.before(baseElement, topElement);
    f$.remove(baseElement);

    let childCD = null;
    let childElement = null;
    
    function insertBlock(result) {
      $router.result = Object.assign($router.result, result);
      if(childCD) return;
  
      let event = new CustomEvent('route-to');
      event.value = result;
      baseElement.dispatchEvent(event);
  
      childCD = parentCD.new();
      childCD.$router = $router;
      childElement = baseElement.cloneNode(true);
      f$.after(topElement, childElement);
      alight.bind(childCD, childElement, {skip_attr: env.skippedAttr()});
    }
  
    function removeBlock(destroyed) {
      if(outCondition) {
        alight.router.unsubscribe(outCondition, 'out');
        outCondition = null;
      }
      if(!childCD) return;
      if(!destroyed) childCD.destroy();
      f$.remove(childElement);
      childCD = null;
      childElement = null;
    }
    
    let result = route.test(alight.router.getCurrentUrl());
    flagUrl = !!result;
    if(flagUrl || flagDefault) {
      insertBlock(result);
    }
    
  }
}

alight.d.al.routeOut = function(scope, element, expression, env) {
  let cd = env.changeDetector;
  let $router = cd.$router;
  if(!$router && cd.parent) $router = cd.parent.$router;
  
  if(!$router) throw 'al-router is not found'
  
  $router.setOut(() => scope.$eval(expression))
}

alight.d.al.routeOut2 = function(scope, element, expression, env) {
  let fn = scope.$compile(expression, {input: ['$url']});
  let handler = ($url) => {
    return fn(scope, $url)
  }
  alight.router.subscribe(handler, 'out2')
  scope.$watch('$destroy', () => {
    alight.router.unsubscribe(handler, 'out2')
  })
}

alight.hooks.scope.push({
  code: '$route',
  fn: function() {
    if(this.scope.$route) return;
    let cd = this.changeDetector;
    if(cd.parent && cd.parent.$router) this.scope.$route = cd.parent.$router.result;
  }
})

alight.d.al.link = function(scope, element, url) {
  element.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    alight.router.go(url);
    scope.$scan({late: true});
  })
}


// coded by rumkin
function routeMatcher(route) {
    var segments = route.replace(/^\/+|\/+$/, '').split(/\/+/);
    var names = [];
    var rules = [];
    
    segments.forEach(function(segment){
      var rule;
      if (segment.charAt(0) === ':') {
        names.push(segment.slice(1));
        rules.push('([^\/]+)');
      } else if (segment === '**') {
        names.push('tail');
        rules.push('(.+)');
      } else {
        rules.push(escapeRegExp(segment));
      }
    });
    
    var regex = new RegExp('^\/' + rules.join('\/') + '\/?$', 'i');
    
    var matcher = function(url) {
      var match = url.match(regex);
      if (! match) {
        return;
      }
      
      var result = {};
      names.forEach(function(name, i) {
        result[name] = match[i + 1];
      });
      
      return result;
    };
    
    return matcher;
  }
  
  function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
};

})();
