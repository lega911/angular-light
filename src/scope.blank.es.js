
function cd_getRoot() {
    throw 'Scope is off'
}

function cd_getActive() {
    throw 'Scope is off'
}

function scopeWrap(cd, fn) {
    return fn()
}

alight.core.cd_getRoot = cd_getRoot
alight.core.cd_getActive = cd_getActive
alight.core.scopeWrap = scopeWrap
