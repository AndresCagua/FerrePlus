import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/repositories/offline_repository.dart';

class ConnectivityMonitorImpl implements ConnectivityMonitor {
  ConnectivityMonitorImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _subscription = _connectivity.onConnectivityChanged
        .map(
          (List<ConnectivityResult> value) =>
              value.isNotEmpty && !value.contains(ConnectivityResult.none),
        )
        .distinct()
        .debounce(const Duration(milliseconds: 750))
        .listen(_onlineController.add);
  }
  final Connectivity _connectivity;
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();
  late final StreamSubscription<bool> _subscription;

  @override
  Stream<bool> get stabilizedOnline => _onlineController.stream;

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _onlineController.close();
  }
}

extension on Stream<bool> {
  Stream<bool> debounce(Duration duration) {
    late StreamController<bool> controller;
    Timer? timer;
    controller = StreamController<bool>(
      onListen: () {
        final StreamSubscription<bool> subscription = listen(
          (bool value) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(value));
          },
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
        controller.onCancel = () async {
          timer?.cancel();
          await subscription.cancel();
        };
      },
    );
    return controller.stream;
  }
}
