import '../../../core/utils/safe_change_notifier.dart';
import '../models/shell_state.dart';

class ShellViewModel extends SafeChangeNotifier {
  ShellState _state = const ShellState();

  ShellState get state => _state;

  void setIndex(int index) {
    if (_state.currentIndex == index) {
      return;
    }
    _state = _state.copyWith(currentIndex: index);
    notifyListeners();
  }
}
