// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0

/// BLE Protocol Constants
/// Based on MeshCore companion radio BLE implementation
/// Reference: meshcore-team/app/src/main/java/com/meshcore/team/data/ble/BleConstants.kt
class BleConstants {
  // Nordic UART Service (NUS) UUIDs
  static const String serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String rxCharacteristicUuid =
      '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // Write (app→device)
  static const String txCharacteristicUuid =
      '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // Notify (device→app)

  // Device name prefix
  static const String deviceNamePrefix = 'MeshCore-';

  // Frame protocol
  static const int maxFrameSize = 172; // bytes
  static const int minWriteIntervalMs = 60; // milliseconds between writes

  // Command codes (sent from app to device)
  static const int cmdAppStart = 1;
  static const int cmdSendTxtMsg = 2; // Send direct message
  static const int cmdSendChannelTxtMsg = 3; // Send channel message
  static const int cmdGetContacts = 4;
  static const int cmdGetDeviceTime = 5;
  static const int cmdSetDeviceTime = 6;
  static const int cmdSendSelfAdvert = 7;
  static const int cmdSetAdvertName = 8;
  static const int cmdAddUpdateContact = 9;
  static const int cmdSyncNextMessage = 10; // Poll for new messages
  static const int cmdSetRadioParams = 11;
  static const int cmdSetRadioTxPower = 12;
  static const int cmdSetAdvertLatLon = 14;
  static const int cmdRemoveContact = 15;
  static const int cmdReboot = 19;
  static const int cmdDeviceQuery = 22; // CORRECT VALUE FROM ANDROID TEAM
  static const int cmdGetChannel = 31;
  static const int cmdSetChannel = 32;
  static const int cmdSendTelemetryReq = 39;

  // 57+ range: upstream firmware added new commands; custom commands were moved.
  static const int cmdSendAnonReq = 57;
  static const int cmdSetAutoAddConfig = 58;
  static const int cmdGetAutoAddConfig = 59;
  static const int cmdGetAllowedRepeatFreq = 60;
  static const int cmdGetRadioSettings = 200;
  static const int cmdSetMaxHops = 201;
  static const int cmdSetForwardList = 202;
  static const int cmdGetAutonomousSettings = 203;
  static const int cmdSetAutonomousSettings = 204;

  // Response codes (received from device)
  static const int respOk = 0;
  static const int respErr = 1;
  static const int respContactsStart = 2;
  static const int respContact = 3;
  static const int respEndOfContacts = 4;
  static const int respSelfInfo = 5;
  static const int respSent = 6;
  static const int respNoMoreMessages = 10;
  static const int respDeviceInfo = 13;
  static const int respContactMsgRecvV3 = 16; // Incoming DM (v3)
  static const int respChannelMsgRecvV3 = 17; // Incoming channel message (v3)
  static const int respChannelInfo = 18;

  // v8+ responses
  static const int respStats = 24;
  static const int respAutoAddConfig = 25;
  static const int respAllowedRepeatFreq = 26;
  static const int respAutonomousSettings = 200;

  // Push codes (async notifications from device)
  static const int pushCodeAdvert = 0x80; // Contact discovered
  static const int pushCodePathUpdated = 0x81; // Routing path updated
  static const int pushCodeSendConfirmed = 0x82; // Message ACK received
  static const int pushCodeMsgWaiting = 0x83; // New message available
  static const int pushCodeLogRxData = 0x88; // Raw packet log
  static const int pushCodeNewAdvert = 0x8A; // New discovery
  static const int pushCodeTelemetryResponse = 0x8B; // Telemetry response

  // Message delivery status
  static const String deliveryStatusSending = 'SENDING';
  static const String deliveryStatusSent = 'SENT';
  static const String deliveryStatusDelivered = 'DELIVERED';

  BleConstants._(); // Private constructor to prevent instantiation
}
