var page = require('webpage').create();
var url = './test/run.html';

page.onConsoleMessage = function(msg) {
	console.log(': ' + msg);
};

page.open(url, function (status) {
	console.log('Status', status);
	//Page is loaded!
	setTimeout(function(){
		console.log('run test in a browser is a better way');
		phantom.exit();
	}, 5000);
});
