import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:reversisockets/enum/messages.dart';
import 'package:reversisockets/enum/socket_events.dart';
import '../services/socket.dart';

const Color grayColor = Colors.grey;
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final List<List<Color>> _board =
      List.generate(8, (_) => List.filled(8, grayColor));
  Color currentColor = blackColor;
  final SocketClient _client = SocketClient();
  bool canPlay = false;
  bool hasFirst = false;
  bool black = true;

  @override
  void initState() {
    super.initState();
    _client.connect();
    _handleComingMessage();
    _initializeBoard();
  }

  void _initializeBoard() {
    _board[3][3] = whiteColor;
    _board[3][4] = blackColor;
    _board[4][3] = blackColor;
    _board[4][4] = whiteColor;
    setState(() {});
  }

  void _handleFirstPlayer() {
    _client.firstPlayer(playerTurn: 1);
    setState(() {
      hasFirst = true;
      canPlay = true;
      black = false;
    });
  }

  void _turnStart() {
    setState(() {
      canPlay = true;
    });
  }

  void _turnEnd() {
    setState(() {
      canPlay = false;
    });
  }

  _handleGivUp() {
    final SnackBar snackbar = SnackBar(
      content: Text(
        Messages.givUpRequest,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.yellowAccent,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    _client.giveUp(playerColor: Colors.black);
  }

  void _handleComingMessage() {
    _client.socket.on(SocketEvents.boardMovement.event, (data) {
      var enemyMove = jsonDecode(data);
      setState(() {
        _flipPieces(enemyMove['h'], enemyMove['v'], black ? 0 : 1);
        _board[enemyMove['h']][enemyMove['v']] =
            !black ? blackColor : whiteColor;
        _turnStart();
      });
    });

    _client.socket.on(SocketEvents.turnEnd.event, (data) {
      setState(() {
        canPlay = true;
      });
    });

    _client.socket.on(SocketEvents.firstPlayer.event, (data) {
      _hasFirst();
    });

    _client.socket.on(
      SocketEvents.turnEnd.event,
      (data) {
        _turnStart();
      },
    );

    _client.socket.on(
      SocketEvents.giveUp.event,
      (data) {
        _showGivUpRequest();
      },
    );

    _client.socket.on(
      SocketEvents.aceptGiveUp.event,
      (data) {
        final SnackBar snackbar = SnackBar(
          content: Text(Messages.loseByGivingUp),
          backgroundColor: Colors.red,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
        _resetBoard();
      },
    );
  }

  void _showGivUpRequest() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desistencia!'),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Text('O adversário quer desistir do jogo!'),
                Text('Caso aceite , você será o  vencedor!')
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('Não Aceitar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'Aceitar',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                _aceptPlayerGivenUp();
              },
            ),
          ],
        );
      },
    );
  }

  _aceptPlayerGivenUp() {
    Navigator.of(context).pop();
    final SnackBar snackbar = SnackBar(
      content: Text(Messages.winTheGame),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
    _client.socket.emit(SocketEvents.aceptGiveUp.event, 1);
    _resetBoard();
  }

  void _showVictory() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vencedor!'),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Text('Parabéns, venceu o jogo!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                _aceptPlayerGivenUp();
              },
            ),
          ],
        );
      },
    );
  }

  void _hasFirst() {
    setState(() {
      canPlay = false;
      hasFirst = true;
    });
  }

  void _makeMove(int x, int y, bool color) {
    setState(() {
      _board[x][y] = color ? blackColor : whiteColor;
      _flipPieces(x, y, color ? 1 : 0);
      canPlay = false;
      currentColor = currentColor == blackColor ? whiteColor : blackColor;
    });
    _client.sendBoardMove(
      x,
      y,
    );
    _turnEnd();
    _checkWinner();
  }

  void _flipPieces(int x, int y, int color) {
    int opponent = color == 1 ? 2 : 1;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = x + dx;
        int ny = y + dy;
        List<Offset> toFlip = [];

        while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
          if (_board[nx][ny] == (opponent == 1 ? blackColor : whiteColor)) {
            toFlip.add(Offset(nx.toDouble(), ny.toDouble()));
          } else if (_board[nx][ny] == (color == 1 ? blackColor : whiteColor)) {
            for (Offset pos in toFlip) {
              _board[pos.dx.toInt()][pos.dy.toInt()] =
                  (color == 1 ? blackColor : whiteColor);
            }
            break;
          } else {
            break;
          }
          nx += dx;
          ny += dy;
        }
      }
    }
  }

  void _checkWinner() {
    int blackCount =
        _board.expand((row) => row).where((cell) => cell == blackColor).length;
    int whiteCount =
        _board.expand((row) => row).where((cell) => cell == whiteColor).length;

    if (blackCount + whiteCount == 64 || blackCount == 0 || whiteCount == 0) {
      String winnerMessage = blackCount > whiteCount
          ? 'Jogador Preto venceu!'
          : 'Jogador Branco venceu!';
      _showVictoryDialog(winnerMessage);
    }
  }

  void _showVictoryDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vencedor!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetBoard();
            },
            child: const Text('Reiniciar Jogo'),
          ),
        ],
      ),
    );
  }

  void _resetBoard() {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        _board[i][j] = grayColor;
      }
    }
    canPlay = false;
    hasFirst = false;
    _initializeBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Linha de letras (A-H)
        Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(9, (index) {
            return index == 0
                ? const SizedBox(
                    width: 40,
                    height: 40,
                  )
                : Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + index - 1), // Letras A-H
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
          }),
        ),
        // Tabuleiro
        Expanded(
          child: Column(
            children: List.generate(8, (x) {
              return Row(
                children: [
                  // Números (1-8)
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${x + 1}', // Números 1-8
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  // Células do tabuleiro
                  for (int y = 0; y < 8; y++)
                    GestureDetector(
                      onTap: () {
                        if (canPlay && _isValidMove(x, y)) {
                          _makeMove(x, y, black ? true : false);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          color: _board[x][y],
                        ),
                        child: Center(
                          child: Text(
                            _board[x][y] == blackColor
                                ? 'B'
                                : _board[x][y] == whiteColor
                                    ? 'W'
                                    : '',
                            style: TextStyle(
                                fontSize: 24,
                                color: _board[x][y] == blackColor
                                    ? Colors.white
                                    : _board[x][y] == whiteColor
                                        ? Colors.black
                                        : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
        !hasFirst
            ? SizedBox()
            : black
                ? Text('Você é o preto.')
                : Text('Você é o branco'),
        !hasFirst
            ? ElevatedButton(
                onPressed: _handleFirstPlayer,
                child: const Text('Ser o primeiro.'),
              )
            : Text(canPlay ? "Sua vez" : "Aguarde o turno do jogador"),
        const SizedBox(
          height: 25,
        ),
        ElevatedButton(
          onPressed: _resetBoard,
          child: const Text('Reiniciar'),
        ),
        const SizedBox(
          height: 25,
        ),
        if (hasFirst)
          ElevatedButton(
            onPressed: _handleGivUp,
            child: const Text('Desistir'),
          ),
      ],
    );
  }

  bool _isValidMove(int x, int y) {
    // Adicione lógica para validar o movimento
    return _board[x][y] == grayColor; // Simples validação
  }
}
