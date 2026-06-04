import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/match_model.dart';
import '../models/prediction_model.dart';

class MatchesProvider extends ChangeNotifier {
  String _sport = 'baseball';
  DateTime _selectedDate = DateTime.now();
  List<MatchModel> _matches = [];
  bool _loading = false;
  String? _error;
  final Map<int, PredictionModel> _predictions = {};
  final Set<int> _loadingPredictions = {};
  final Set<int> _paywalled = {};

  String get sport => _sport;
  DateTime get selectedDate => _selectedDate;
  List<MatchModel> get matches => _matches;
  bool get loading => _loading;
  String? get error => _error;

  PredictionModel? prediction(int matchId) => _predictions[matchId];
  bool isPredictionLoading(int matchId) => _loadingPredictions.contains(matchId);
  bool isPaywalled(int matchId) => _paywalled.contains(matchId);

  Future<void> loadMatches({String? token, bool syncLive = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Si se solicita sync en vivo (béisbol, fecha de hoy), actualizar scores primero
      if (syncLive && _sport == 'baseball') {
        try {
          await ApiClient(token: token).post('/api/admin/sync-live', {});
          await Future.delayed(const Duration(seconds: 3));
        } catch (_) {} // Ignorar si falla el sync — igual cargamos los datos
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final data = await ApiClient(token: token)
          .get('/api/matches?sport=$_sport&match_date=$dateStr');
      _matches = (data as List).map((e) => MatchModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Sin conexión con el servidor';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPrediction(int matchId, {String? token}) async {
    if (_loadingPredictions.contains(matchId)) return;
    _loadingPredictions.add(matchId);
    notifyListeners();
    try {
      final data = await ApiClient(token: token).get('/api/predictions/$matchId');
      _predictions[matchId] = PredictionModel.fromJson(data);
      _paywalled.remove(matchId);
    } on ApiException catch (e) {
      if (e.statusCode == 402) _paywalled.add(matchId);
    } catch (_) {
    } finally {
      _loadingPredictions.remove(matchId);
      notifyListeners();
    }
  }

  Future<void> refreshPrediction(int matchId, {String? token}) async {
    if (_loadingPredictions.contains(matchId)) return;
    _loadingPredictions.add(matchId);
    _predictions.remove(matchId);
    notifyListeners();
    try {
      final data = await ApiClient(token: token)
          .post('/api/predictions/$matchId/refresh', {});
      _predictions[matchId] = PredictionModel.fromJson(data);
    } catch (_) {
    } finally {
      _loadingPredictions.remove(matchId);
      notifyListeners();
    }
  }

  void setSport(String sport, {String? token}) {
    if (_sport == sport) return;
    _sport = sport;
    _matches = [];
    _predictions.clear();
    loadMatches(token: token);
  }

  void setDate(DateTime date, {String? token}) {
    _selectedDate = date;
    _matches = [];
    loadMatches(token: token);
  }
}
