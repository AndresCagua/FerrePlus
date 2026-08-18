import 'failure.dart';

String userFailureMessage(Object error) => error is Failure
    ? error.message
    : 'No se pudo completar la operacion. Intenta nuevamente.';
