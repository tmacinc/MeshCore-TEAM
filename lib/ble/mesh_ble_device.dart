import 'package:flutter/foundation.dart';

@immutable
class MeshBleDevice {
  final String address;
  final String name;

  const MeshBleDevice({
    required this.address,
    required this.name,
  });

  @override
  bool operator ==(Object other) {
    return other is MeshBleDevice &&
        other.address.toUpperCase() == address.toUpperCase();
  }

  @override
  int get hashCode => address.toUpperCase().hashCode;

  @override
  String toString() => 'MeshBleDevice(name: $name, address: $address)';
}
