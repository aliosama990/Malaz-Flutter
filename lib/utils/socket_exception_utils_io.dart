import 'dart:io';

bool isSocketException(Object error) => error is SocketException;

String describeSocketException(Object error) {
  final socketError = error as SocketException;
  return <String>[
    'SocketException',
    'osError: ${socketError.osError}',
    'address: ${socketError.address}',
    'port: ${socketError.port}',
    'exception: $socketError',
  ].join('\n');
}
