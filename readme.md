
### Angular Light
Web framework with MVC model. Angular.js + Knockout.js way.

Visit [angularlight.org](http://angularlight.org/)

### Example 0
``` html
<div al-app>
    <label>Name:</label>
    <input type="text" al-value="name" />
    <h3>Hello {{name}}!</h3>
</div>
```

### Example 1
``` html
<div id="app">
    <input al-value="data.name" type="text" />
    {{data.name}} <br/>
    <button al-click="click()">Set Hello</button>
</div>
```

``` js
alight.bootstrap({
    $el: '#app',
    data: {
        name: 'Some text'
    },
    click: function() {
        this.data.name = 'Hello'
    }
});
```

[More examples](http://angularlight.org/doc/examples.html)

### Browser Support
Google Chrome, Firefox, IE9+ (IE8 with jQuery)

### Install with bower
```bower install alight```

### Building and testing
```
npm install
gulp
gulp test
```

Sources of 0.7.15 and older ones there: https://bitbucket.org/lega911

### License
[MIT](http://opensource.org/licenses/MIT)

Copyright (c) 2013 - 2015 Oleg Nechaev <lega911@gmail.com>
