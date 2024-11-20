class SocketEvents {
  final String event;

  SocketEvents._(this.event);

  static final SocketEvents boardMovement = SocketEvents._('board-moviment');
  static final SocketEvents message = SocketEvents._('message');
  static final SocketEvents giveUp = SocketEvents._('give-up');
  static final SocketEvents aceptGiveUp = SocketEvents._('acept-give-up');
  static final SocketEvents turnEnd = SocketEvents._('turn-end');
  static final SocketEvents firstPlayer = SocketEvents._('first-player');
}
