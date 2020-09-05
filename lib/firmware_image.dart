import 'dart:typed_data';

/// Firmware image info
class FirmwareImage {
  final int slot;
  final String version;
  final Uint8List hash; //List<int> hash;
  final String hashStr;
  final Map<String, bool> flags;

  FirmwareImage({this.slot, this.version, this.hash, this.hashStr, this.flags});

  factory FirmwareImage.fromJson(Map<String, dynamic> json) {
    return FirmwareImage(
      slot: json['slot'],
      version: json['version'],
      hash: Uint8List.fromList(json['hash'].cast<int>()),
      hashStr: json['hashStr'],
      flags: Map<String, bool>.from(json['flags']),
    );
  }

  @override
  String toString() {
    return "slot: $slot\n"
        "version: $version\n"
        "hash: $hash\n"
        "hashStr: $hashStr\n"
        "flags: $flags\n";
  }
}

// TODO: use enum instead fo string?
// enum Flags {
//   bootable,
//   pending,
//   confirmed,
//   active,
//   permanent,
// }
