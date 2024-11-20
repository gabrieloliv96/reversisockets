import 'package:flutter/material.dart';
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
  bool canPlay = true;

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

  void _handleComingMessage() {
    _client.socket.on(SocketEvents.boardMovement.event, (data) {
      List<int> move = List<int>.from(data);
      _makeMove(move[0], move[1], move[2]);
    });

    _client.socket.on(SocketEvents.turnEnd.event, (data) {
      setState(() {
        canPlay = true;
      });
    });
  }

  void _makeMove(int x, int y, int color) {
    setState(() {
      _board[x][y] = color == 1 ? blackColor : whiteColor;
      _flipPieces(x, y, color);
      canPlay = false;
      currentColor = currentColor == blackColor ? whiteColor : blackColor;
    });
    _client.sendBoardMove(x, y, currentColor == blackColor ? 1 : 2);
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
    _initializeBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
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
                            _makeMove(x, y, currentColor == blackColor ? 1 : 2);
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
                              style:  TextStyle(fontSize: 24, color:_board[x][y] == blackColor
                                  ? Colors.white
                                  : _board[x][y] == whiteColor
                                      ? Colors.black
                                      : Colors.grey ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
          ElevatedButton(
            onPressed: _resetBoard,
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  bool _isValidMove(int x, int y) {
    // Adicione lógica para validar o movimento
    return _board[x][y] == grayColor; // Simples validação
  }
}
