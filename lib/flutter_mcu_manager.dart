import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'firmware_image.dart';

// TODO: manage ble connections as well?
// TODO: if mac address is constant reconect device after reset
// TODO: handle exceptions

/// Manages reading and writing files to device (identified by mac addr)
///
/// Wrapper around native mcumgr libs
class FlutterMcuManager {
  static const String NAMESPACE = 'korantom.flutter_mcumgr';

  static const MethodChannel _methodChannel =
      const MethodChannel('$NAMESPACE/method');

  static const EventChannel _uploadProgressEventChannel =
      const EventChannel('$NAMESPACE/event/upload/progress');
  static const EventChannel _upgradeProgressEventChannel =
      const EventChannel('$NAMESPACE/event/upgrade/progress');
  static const EventChannel _fileDownloadProgressEventChannel =
      const EventChannel('$NAMESPACE/event/file/progress');
  static const EventChannel _uploadStatusEventChannel =
      const EventChannel('$NAMESPACE/event/upload/status');
  static const EventChannel _upgradeStatusEventChannel =
      const EventChannel('$NAMESPACE/event/upgrade/status');
  static const EventChannel _fileDownloadStatusEventChannel =
      const EventChannel('$NAMESPACE/event/file/status');

  /* ------------------------------------------------------------------------ */

  static Stream<double> _uploadProgressStream;
  static Stream<double> _upgradeProgressStream;
  static Stream<double> _fileDownlaodProgressStream;
  static Stream<String> _uploadStatusStream;
  static Stream<String> _upgradeStatusStream;
  static Stream<String> _fileDownloadStatusStream;

  /// Firmware upload progress
  static Stream<double> get uploadProgressStream {
    if (_uploadProgressStream == null) {
      _uploadProgressStream = _uploadProgressEventChannel
          .receiveBroadcastStream()
          .map<double>((value) => value);
    }

    return _uploadProgressStream;
  }

  /// Firmware upgrade progress
  static Stream<double> get ugradeProgressStream {
    if (_upgradeProgressStream == null) {
      _upgradeProgressStream = _upgradeProgressEventChannel
          .receiveBroadcastStream()
          .map<double>((value) => value);
    }

    return _upgradeProgressStream;
  }

  /// Firmware upload progress
  static Stream<double> get fileDownlaodProgressStream {
    if (_fileDownlaodProgressStream == null) {
      _fileDownlaodProgressStream = _fileDownloadProgressEventChannel
          .receiveBroadcastStream()
          .map<double>((value) => value);
    }

    return _fileDownlaodProgressStream;
  }

  // TODO: status enum?

  /// Firmware upload status (File not found, paused, running etc..)
  static Stream<String> get uploadStatusStream {
    if (_uploadStatusStream == null) {
      _uploadStatusStream = _uploadStatusEventChannel
          .receiveBroadcastStream()
          .map<String>((value) => value);
    }

    return _uploadStatusStream;
  }

  /// Firmware upgrade status (File not found, paused, running etc..)
  static Stream<String> get upgradeStatusStream {
    if (_upgradeStatusStream == null) {
      _upgradeStatusStream = _upgradeStatusEventChannel
          .receiveBroadcastStream()
          .map<String>((value) => value);
    }

    return _upgradeStatusStream;
  }

  /// File Download status (File not found, paused, running etc..)
  static Stream<String> get fileDownloadStatusStream {
    if (_fileDownloadStatusStream == null) {
      _fileDownloadStatusStream = _fileDownloadStatusEventChannel
          .receiveBroadcastStream()
          .map<String>((value) => value);
    }

    return _fileDownloadStatusStream;
  }

  /* ------------------------------------------------------------------------ */

  /// Sends a message to device, returns reply if device supports smp and can connect to device
  static Future<String> echo(String macAddress, String message) async {
    final String reply =
        await _methodChannel.invokeMethod('echo', <String, dynamic>{
      'macAddress': macAddress,
      'message': message,
    });
    return reply;
  }

  /* ------------------------------------------------------------------------ */

  /// Init classes for upcoming operations
  static Future<bool> connect(String macAddress) async {
    try {
      await _methodChannel.invokeMethod('connect', <String, dynamic>{
        'macAddress': macAddress,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /* ------------------------------------------------------------------------ */

  /// Reads all images on device
  static Future<List<FirmwareImage>> read() async {
    final String imagesJson =
        await _methodChannel.invokeMethod('read', <String, dynamic>{});

    final parsed = jsonDecode(imagesJson).cast<Map<String, dynamic>>();
    final List<FirmwareImage> images = parsed
        .map<FirmwareImage>((json) => FirmwareImage.fromJson(json))
        .toList();

    return images;
  }

  /* ------------------------------------------------------------------------ */

  /// Load image from mobile phone (prepare for upload, TODO: check hash etc.)
  static Future<void> load(String filePath) async {
    await _methodChannel.invokeMethod('load', <String, dynamic>{
      'filePath': filePath,
    });
  }

  /* ------------------------------------------------------------------------ */

  /// Upload image to device
  static Future<void> upload() async {
    await _methodChannel.invokeMethod('upload', <String, dynamic>{});
  }

  /// Pause image upload
  static Future<void> pauseUpload() async {
    await _methodChannel.invokeMethod('pauseUpload', <String, dynamic>{});
  }

  /// Resume image upload
  static Future<void> resumeUpload() async {
    await _methodChannel.invokeMethod('resumeUpload', <String, dynamic>{});
  }

  /// Cancel image upload
  static Future<void> cancelUpload() async {
    await _methodChannel.invokeMethod('cancelUpload', <String, dynamic>{});
  }

  /* ------------------------------------------------------------------------ */

  /// Upload image to device, swap and reset
  static Future<void> upgrade() async {
    await _methodChannel.invokeMethod('upgrade', <String, dynamic>{});
  }

  /// Pause image upgrade
  static Future<void> pauseUpgrade() async {
    await _methodChannel.invokeMethod('pauseUpgrade', <String, dynamic>{});
  }

  /// Resume image upgrade
  static Future<void> resumeUpgrade() async {
    await _methodChannel.invokeMethod('resumeUpgrade', <String, dynamic>{});
  }

  /// Cancel image upgrade
  static Future<void> cancelUpgrade() async {
    await _methodChannel.invokeMethod('cancelUpgrade', <String, dynamic>{});
  }

  /* ------------------------------------------------------------------------ */

  ///
  static Future<String> sendTextCommand(String text) async {
    final String result =
        await _methodChannel.invokeMethod('sendTextCommand', <String, dynamic>{
      'text': text,
    });
    return result;
  }

  /// Read a file from device file system
  static Future<String> readFile(String filePath) async {
    final fileContent =
        await _methodChannel.invokeMethod('readFile', <String, dynamic>{
      'filePath': filePath,
    });
    return fileContent;
  }

  /// Saves a string as txt file to mobile phone file system
  static Future<void> saveFile(String filePath, String fileContent) async {
    await _methodChannel.invokeMethod('saveFile', <String, dynamic>{
      'filePath': filePath,
      'fileContent': fileContent,
    });
  }

  /* ------------------------------------------------------------------------ */

  /// TODO:
  static Future<void> test(String macAddress, List<Uint8> hash) async {
    return;
  }

  /// Swaps images in slot 0 and 1
  static Future<void> confirm(Uint8List hash) async {
    await _methodChannel.invokeMethod('confirm', <String, dynamic>{
      'hash': hash,
    });
  }

  /// Deletes image in slot 1 if present
  static Future<void> erase() async {
    await _methodChannel.invokeMethod('erase', <String, dynamic>{});
  }

  /// Restarts device and applies changes
  static Future<void> reset() async {
    await _methodChannel.invokeMethod('reset', <String, dynamic>{});
  }
}
