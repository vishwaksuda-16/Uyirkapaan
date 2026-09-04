import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

/// Local DataSource for persisting active emergency request ID and offline state.
abstract class RequestLocalDataSource {
  Future<void> saveActiveRequestId(String requestId);
  Future<String?> getActiveRequestId();
  Future<void> clearActiveRequestId();
}

class RequestLocalDataSourceImpl implements RequestLocalDataSource {
  final SharedPreferences? _prefs;

  RequestLocalDataSourceImpl([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveActiveRequestId(String requestId) async {
    final prefs = await _getPrefs();
    await prefs.setString(AppConstants.keyActiveRequestId, requestId);
  }

  @override
  Future<String?> getActiveRequestId() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyActiveRequestId);
  }

  @override
  Future<void> clearActiveRequestId() async {
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.keyActiveRequestId);
  }
}
