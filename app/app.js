var http = require('http');
var os = require('os');

var port = 80;
var version = '0.1'; // for test purpose

var server = http.createServer(function (req, res) {
  if (req.method == 'GET' && req.url === '/') {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('I am: ' + os.hostname() + '. This is Ads API version:' + version + '\n');
  }
  else if (req.method == 'GET' && req.url === '/ad') {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('I am: ' + os.hostname() + '. This is GET /ad  API\n');
  }
  else if (req.method == 'POST' && req.url === '/ad-event') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('I am: ' + os.hostname() + '. This is POST /ad-event API\n');
  }
  else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 error! Page not found.\n');
  }
}).listen(port);
console.log('Server running at http://127.0.0.1:' + port);
