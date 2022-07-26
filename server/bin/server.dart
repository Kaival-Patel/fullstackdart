import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:hotreloader/hotreloader.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Configure routes.
int counter = 0;
late Socket socket;
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
  //dart --enable-vm-service bin/server.dart
  // Use any available host or container IP (usually `0.0.0.0`).
  final reloader = await HotReloader.create();
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  //SQL CONNECTION
  try {
    // socket = await Socket.connect('localhost', 3306);
    // print("Connected SQL Server on ${socket.port}");
    // String json = jsonEncode({
    //   "type": "open",
    //   "text":
    //       "Server=localhost\\SQLEXPRESS;Database=Test123;Trusted_Connection=yes;"
    // });
    // // String json = jsonEncode({"type": "table", "text": "SELECT * FROM Test"});
    // _sendCommand(json).then((result) {
    //   print("DB RESULT => $result");
    // }).catchError((err) {
    //   print('Querying Error');
    // });
    var settings = ConnectionSettings(
        host: 'localhost', port: 3306, user: 'root', db: 'test123');
    var conn = await MySqlConnection.connect(settings);
    print(await conn.query('SELECT * FROM tt'));
  } catch (e) {
    print(e);
  }

  // For running in containers, we respect the PORT environment variable.
  //PORT 8080
  final port = int.parse('8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
  reloader.stop();
}

Future<String> _sendCommand(String command) {
  // prepare buffer for response
  StringBuffer receiveBuffer = StringBuffer();

  Completer<String> _completer = Completer();
  String cmd = command.length.toString() + "\r\n" + command;
  print(cmd);
  socket.write(cmd);

  return _completer.future;
}
