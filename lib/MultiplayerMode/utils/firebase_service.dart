import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:bhagchal/MultiplayerMode/models/multiplayer_game_state.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _uuid = const Uuid();
  StreamSubscription? _gameStateSubscription;
  StreamSubscription? _connectionSubscription;

  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  Future<String> createGame(String playerId) async {
    final gameId = _uuid.v4();
    final gameRef = _database.child('games/$gameId');

    await gameRef.set({
      'host': playerId,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'players': {
        playerId: {
          'role': 'host',
          'connected': true,
          'lastSeen': ServerValue.timestamp,
        },
      },
    });

    return gameId;
  }

  Future<void> joinGame(String gameId, String playerId) async {
    final gameRef = _database.child('games/$gameId');
    final gameSnapshot = await gameRef.get();

    if (!gameSnapshot.exists) {
      throw Exception('Game not found');
    }

    final gameData = gameSnapshot.value as Map<dynamic, dynamic>;
    if (gameData['status'] != 'waiting') {
      throw Exception('Game is not available');
    }

    await gameRef.update({
      'status': 'in_progress',
      'players/$playerId': {
        'role': 'guest',
        'connected': true,
        'lastSeen': ServerValue.timestamp,
      },
    });
  }

  Stream<MultiplayerGameState> watchGameState(String gameId, String playerId) {
    final gameRef = _database.child('games/$gameId');
    return gameRef.onValue.map((event) {
      if (!event.snapshot.exists) return MultiplayerGameState.empty();

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return MultiplayerGameState.fromJson(data, playerId);
    });
  }

  Future<void> updateGameState(
    String gameId,
    MultiplayerGameState state,
  ) async {
    final gameRef = _database.child('games/$gameId');
    await gameRef.update(state.toJson());
  }

  Future<void> updatePlayerStatus(
    String gameId,
    String playerId,
    bool connected,
  ) async {
    final gameRef = _database.child('games/$gameId/players/$playerId');
    await gameRef.update({
      'connected': connected,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> leaveGame(String gameId, String playerId) async {
    final gameRef = _database.child('games/$gameId');
    await gameRef.child('players/$playerId').remove();

    // Check if game is empty and remove it
    final gameSnapshot = await gameRef.get();
    if (gameSnapshot.exists) {
      final gameData = gameSnapshot.value as Map<dynamic, dynamic>;
      if (gameData['players'] == null || (gameData['players'] as Map).isEmpty) {
        await gameRef.remove();
      }
    }
  }

  void dispose() {
    _gameStateSubscription?.cancel();
    _connectionSubscription?.cancel();
  }
}
