# taken from http://www.piware.de/2011/01/creating-an-https-server-in-python/
# run as follows:
#    python simple-https-server.py
# then in your browser, visit:
#    https://localhost:4443

import BaseHTTPServer, SimpleHTTPServer
import ssl

httpd = BaseHTTPServer.HTTPServer(('0.0.0.0', 4443), SimpleHTTPServer.SimpleHTTPRequestHandler)
#httpd.socket = ssl.wrap_socket (httpd.socket, certfile='./server.pem', server_side=True)
httpd.socket = ssl.wrap_socket (httpd.socket, keyfile='./server.key', certfile='./server.crt', server_side=True)
httpd.serve_forever()
