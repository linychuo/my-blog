const http = require('http');
const fs = require('fs');
const port = process.argv[2] || 8000;
const rootDir = process.argv[3] || './_posts';

http.createServer(function (req, res) {
	console.log(`${req.method} ${req.url}`);
	let fullpath = `${rootDir}${req.url}`;

	fs.exists(fullpath, function (exist) {
		if (!exist) {
			res.statusCode = 404;
			res.end(`File ${req.url} not found!`);
			return;
		}

		fs.readFile(fullpath, function (err, data) {
			if (err) {
				res.statusCode = 500;
				res.end(`Error getting the file: ${err}.`);
			} else {
				res.statusCode = 200;
				res.setHeader('Access-Control-Allow-Origin', '*');
				//res.setHeader('Content-Type', 'text/plain; charset=utf-8');
				res.end(data);
			}
		});
	});
}).listen(parseInt(port));

console.log(`Server listening on port ${port}`);
