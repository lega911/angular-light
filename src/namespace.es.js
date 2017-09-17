function Namespace(alight, name) {
  this.alight = alight;
  this.name = name;
}

Namespace.prototype.directive = function(name, descriptor){
  var directives = this.alight.directives[this.name] || {};

  directives[name] = descriptor;

  this.alight.directives[this.name] = directives;
  return this;
};

Namespace.prototype.directives = function(directives) {
  var self = this;
  Object.getOwnPropertyNames(directives)
  .forEach(function(name) {
    self.directive(name, directives[name]);
  });

  return this;
};

Namespace.prototype.controller = function (name, ctrl) {
  this.alight.ctrl[this.name + name[0].toUpperCase() + name.slice(1)] = ctrl;
  return this;
};

Namespace.prototype.controllers = function(controllers) {
  var self = this;

  Object.getOwnPropertyNames(controllers)
  .forEach(function(name) {
    var fn = controllers[name];
    if (typeof fn !== 'function') {
      return;
    }

    self.controller(name, fn);
  });

  return this;
};

Namespace.prototype.filter = function(name, filter) {
  this.alight.filters[this.name + name[0].toUpperCase() + name.slice(1)] = filter;
  return this;
};

Namespace.prototype.filters = function(filters) {
  var self = this;
  Object.getOwnPropertyNames(filters)
  .forEach(function(name) {
    var fn = filters[name];
    if (typeof fn !== 'function') {
      return;
    }

    self.filter(name, fn);
  });

  return this;
};

alight.namespace = function(name) {
  return new Namespace(this, name);
};
