import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Configure routes.
int counter = 0;
List<WebSocketChannel> clients = [];
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/socket', webSocketHandler(appSocketHandler));

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

void appSocketHandler(WebSocketChannel webSocket) {
  webSocket.sink.add(counter.toString());
  clients.add(webSocket);
  webSocket.stream.listen((message) {
    print('SERVER =>' + message);
    counter++;
    for (final client in clients) {
      client.sink.add(counter.toString());
    }
    // webSocket.sink.close();
  }, onDone: () {
    clients.remove(webSocket);
  });
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final reloader = await HotReloader.create();
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  //PORT 8080
  final port = int.parse('8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
  reloader.stop();
}
