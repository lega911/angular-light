if(window.jQuery) {
    window.jQuery.fn.alight = function(data) {
        let elements = [];
        this.each((i, el) => elements.push(el));
        if(elements.length) alight(elements, data);
    }
}
