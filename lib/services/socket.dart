import 'package:flutter/services.dart';
import 'package:reversisockets/enum/socket_events.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;


class SocketClient {
  static final SocketClient _socketClient = SocketClient._internal();
  io.Socket socket = io.io('http://localhost:3000', {
    'autoConnect': false,
    'transports': ['websocket'],
  });

  SocketClient._internal();
  factory SocketClient() {
    return _socketClient;
  }

  connect() {
    socket.connect();
    socket.onConnectError((data) {});
  }

  sendMessage({required String message}) {
    socket.emit(SocketEvents.message.event, message);
  }

  void sendBoardMove(
   int boardH,
   int boardV,
   int playerColor,
) {
  // Cria um mapa com a jogada do jogador
  Map<String, dynamic> playerMove = {
    'player': playerColor,
    'position': {'h': boardH, 'v': boardV},
  };

  // Envia a jogada através do socket
  socket.emit(SocketEvents.boardMovement.event, playerMove);
}

  giveUp({
    required Color playerColor,
  }) {
    socket.emit(SocketEvents.giveUp.event, playerColor.toString());
  }

  turnEnd({required int playerTurn}) {
    Map turn = {'turn': playerTurn};
    socket.emit(
      SocketEvents.turnEnd.event,
      turn.toString(),
    );
  }

  firstPlayer({required int playerTurn}) {
    Map turn = {'turn': playerTurn};
    socket.emit(
      SocketEvents.firstPlayer.event,
      turn.toString(),
    );
  }
}
