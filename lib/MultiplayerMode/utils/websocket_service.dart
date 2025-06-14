// import 'dart:async';
// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../models/multiplayer_game_state.dart';

// class WebSocketService {
//   WebSocketChannel? _channel;
//   final _gameStateController =
//       StreamController<MultiplayerGameState>.broadcast();
//   final _connectionController = StreamController<bool>.broadcast();
//   bool _isConnected = false;

//   Stream<MultiplayerGameState> get gameStateStream =>
//       _gameStateController.stream;
//   Stream<bool> get connectionStream => _connectionController.stream;
//   bool get isConnected => _isConnected;

//   // Connect to the game server
//   Future<void> connect(String playerId, String roomId, bool isHost) async {
//     try {
//       // TODO: Replace with your actual WebSocket server URL
//       final wsUrl =
//           'ws://your-game-server.com/game?playerId=$playerId&roomId=$roomId&isHost=$isHost';
//       _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

//       _channel!.stream.listen(
//         (message) {
//           final data = json.decode(message);
//           if (data['type'] == 'gameState') {
//             final gameState = MultiplayerGameState.fromJson(
//               data['state'],
//               playerId,
//             );
//             _gameStateController.add(gameState);
//           } else if (data['type'] == 'connectionStatus') {
//             _isConnected = data['connected'];
//             _connectionController.add(_isConnected);
//           }
//         },
//         onError: (error) {
//           print('WebSocket error: $error');
//           _isConnected = false;
//           _connectionController.add(false);
//         },
//         onDone: () {
//           print('WebSocket connection closed');
//           _isConnected = false;
//           _connectionController.add(false);
//         },
//       );

//       _isConnected = true;
//       _connectionController.add(true);
//     } catch (e) {
//       print('Failed to connect to WebSocket: $e');
//       _isConnected = false;
//       _connectionController.add(false);
//     }
//   }

//   // Send game state to opponent
//   void sendGameState(MultiplayerGameState gameState) {
//     if (!_isConnected || _channel == null) return;

//     try {
//       final message = {'type': 'gameState', 'state': gameState.toJson()};
//       _channel!.sink.add(json.encode(message));
//     } catch (e) {
//       print('Failed to send game state: $e');
//     }
//   }

//   // Create a new game room
//   Future<String> createRoom(String playerId) async {
//     if (!_isConnected || _channel == null) {
//       throw Exception('Not connected to server');
//     }

//     try {
//       final message = {'type': 'createRoom', 'playerId': playerId};
//       _channel!.sink.add(json.encode(message));

//       // Wait for room creation response
//       final response = await _channel!.stream.firstWhere((message) {
//         final data = json.decode(message);
//         return data['type'] == 'roomCreated';
//       });

//       final data = json.decode(response);
//       return data['roomId'];
//     } catch (e) {
//       print('Failed to create room: $e');
//       rethrow;
//     }
//   }

//   // Join an existing game room
//   Future<void> joinRoom(String playerId, String roomId) async {
//     if (!_isConnected || _channel == null) {
//       throw Exception('Not connected to server');
//     }

//     try {
//       final message = {
//         'type': 'joinRoom',
//         'playerId': playerId,
//         'roomId': roomId,
//       };
//       _channel!.sink.add(json.encode(message));
//     } catch (e) {
//       print('Failed to join room: $e');
//       rethrow;
//     }
//   }

//   // Disconnect from the server
//   void disconnect() {
//     _channel?.sink.close();
//     _channel = null;
//     _isConnected = false;
//     _connectionController.add(false);
//   }

//   // Dispose resources
//   void dispose() {
//     disconnect();
//     _gameStateController.close();
//     _connectionController.close();
//   }
// }
