import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pt'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Stop reconnecting'**
  String get stopReconnecting;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @selectAnother.
  ///
  /// In en, this message translates to:
  /// **'Select Another'**
  String get selectAnother;

  /// No description provided for @selectMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select Multiple'**
  String get selectMultiple;

  /// No description provided for @keepSharing.
  ///
  /// In en, this message translates to:
  /// **'Keep Sharing'**
  String get keepSharing;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @chooseSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose save location'**
  String get chooseSaveLocation;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @fromFile.
  ///
  /// In en, this message translates to:
  /// **'From File'**
  String get fromFile;

  /// No description provided for @fromQrCode.
  ///
  /// In en, this message translates to:
  /// **'From QR Code'**
  String get fromQrCode;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystemDefault;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @languageDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get languageDeviceDefault;

  /// No description provided for @debugLogs.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get debugLogs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get exportLogs;

  /// No description provided for @noLogEntries.
  ///
  /// In en, this message translates to:
  /// **'No log entries'**
  String get noLogEntries;

  /// No description provided for @noLogsToExport.
  ///
  /// In en, this message translates to:
  /// **'No logs to export'**
  String get noLogsToExport;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @scanningForDevices.
  ///
  /// In en, this message translates to:
  /// **'Scanning for MeshCore devices...'**
  String get scanningForDevices;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @enterDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Enter device name'**
  String get enterDeviceName;

  /// No description provided for @setIdentity.
  ///
  /// In en, this message translates to:
  /// **'Set Identity'**
  String get setIdentity;

  /// No description provided for @configName.
  ///
  /// In en, this message translates to:
  /// **'Config Name'**
  String get configName;

  /// No description provided for @radioSettings.
  ///
  /// In en, this message translates to:
  /// **'Radio Settings'**
  String get radioSettings;

  /// No description provided for @frequencyMhz.
  ///
  /// In en, this message translates to:
  /// **'Frequency (MHz)'**
  String get frequencyMhz;

  /// No description provided for @bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get bandwidth;

  /// No description provided for @spreadingFactor.
  ///
  /// In en, this message translates to:
  /// **'Spreading Factor'**
  String get spreadingFactor;

  /// No description provided for @codingRate.
  ///
  /// In en, this message translates to:
  /// **'Coding Rate'**
  String get codingRate;

  /// No description provided for @presetConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Preset Configuration'**
  String get presetConfiguration;

  /// No description provided for @exportConfig.
  ///
  /// In en, this message translates to:
  /// **'Export Config'**
  String get exportConfig;

  /// No description provided for @importTeamConfig.
  ///
  /// In en, this message translates to:
  /// **'Import Team Config'**
  String get importTeamConfig;

  /// No description provided for @createTeamConfig.
  ///
  /// In en, this message translates to:
  /// **'Create Team Config'**
  String get createTeamConfig;

  /// No description provided for @teamConfig.
  ///
  /// In en, this message translates to:
  /// **'Team Config'**
  String get teamConfig;

  /// No description provided for @shareConfigOffline.
  ///
  /// In en, this message translates to:
  /// **'Share Config Offline'**
  String get shareConfigOffline;

  /// No description provided for @importConfig.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfig;

  /// No description provided for @configExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Config exported successfully'**
  String get configExportedSuccessfully;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get exportFailed;

  /// No description provided for @failedToSetDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Failed to set device name'**
  String get failedToSetDeviceName;

  /// No description provided for @failedToSendAdvert.
  ///
  /// In en, this message translates to:
  /// **'Failed to send advert'**
  String get failedToSendAdvert;

  /// No description provided for @advertSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Advert sent successfully'**
  String get advertSentSuccessfully;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @autonomousMode.
  ///
  /// In en, this message translates to:
  /// **'Autonomous Mode'**
  String get autonomousMode;

  /// No description provided for @campMode.
  ///
  /// In en, this message translates to:
  /// **'Camp Mode'**
  String get campMode;

  /// No description provided for @smartForwarding.
  ///
  /// In en, this message translates to:
  /// **'Smart Forwarding'**
  String get smartForwarding;

  /// No description provided for @forwardingAlgorithmDebug.
  ///
  /// In en, this message translates to:
  /// **'Forwarding algorithm (debug)'**
  String get forwardingAlgorithmDebug;

  /// No description provided for @forwardingDebug.
  ///
  /// In en, this message translates to:
  /// **'Forwarding Debug'**
  String get forwardingDebug;

  /// No description provided for @forwardingV1Tel.
  ///
  /// In en, this message translates to:
  /// **'Forwarding V1 (#TEL)'**
  String get forwardingV1Tel;

  /// No description provided for @topologyT.
  ///
  /// In en, this message translates to:
  /// **'Topology #T'**
  String get topologyT;

  /// No description provided for @autoPreferTopology.
  ///
  /// In en, this message translates to:
  /// **'Auto (prefer topology)'**
  String get autoPreferTopology;

  /// No description provided for @phoneGps.
  ///
  /// In en, this message translates to:
  /// **'Phone GPS'**
  String get phoneGps;

  /// No description provided for @phoneFallback.
  ///
  /// In en, this message translates to:
  /// **'Phone fallback'**
  String get phoneFallback;

  /// No description provided for @phoneAutonomousNoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: Autonomous (no phone)'**
  String get phoneAutonomousNoPhone;

  /// No description provided for @companionGps.
  ///
  /// In en, this message translates to:
  /// **'Companion GPS'**
  String get companionGps;

  /// No description provided for @locationSource.
  ///
  /// In en, this message translates to:
  /// **'Location Source'**
  String get locationSource;

  /// No description provided for @locationTracking.
  ///
  /// In en, this message translates to:
  /// **'Location Tracking'**
  String get locationTracking;

  /// No description provided for @alwaysOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Always On Location'**
  String get alwaysOnLocation;

  /// No description provided for @backgroundLocation.
  ///
  /// In en, this message translates to:
  /// **'Background Location'**
  String get backgroundLocation;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On / Show Over Lock'**
  String get keepScreenOn;

  /// No description provided for @redLightDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Red Light Discipline'**
  String get redLightDiscipline;

  /// No description provided for @batteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimization;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// No description provided for @channelName.
  ///
  /// In en, this message translates to:
  /// **'Channel Name'**
  String get channelName;

  /// No description provided for @addChannel.
  ///
  /// In en, this message translates to:
  /// **'Add Channel'**
  String get addChannel;

  /// No description provided for @addChannelLower.
  ///
  /// In en, this message translates to:
  /// **'Add channel'**
  String get addChannelLower;

  /// No description provided for @channelActions.
  ///
  /// In en, this message translates to:
  /// **'Channel actions'**
  String get channelActions;

  /// No description provided for @createPrivateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create Private Channel'**
  String get createPrivateChannel;

  /// No description provided for @joinHashtagChannel.
  ///
  /// In en, this message translates to:
  /// **'Join Hashtag Channel'**
  String get joinHashtagChannel;

  /// No description provided for @deleteChannel.
  ///
  /// In en, this message translates to:
  /// **'Delete Channel?'**
  String get deleteChannel;

  /// No description provided for @shareChannel.
  ///
  /// In en, this message translates to:
  /// **'Share Channel'**
  String get shareChannel;

  /// No description provided for @shareChannelLower.
  ///
  /// In en, this message translates to:
  /// **'Share channel'**
  String get shareChannelLower;

  /// No description provided for @deriveKeyFromName.
  ///
  /// In en, this message translates to:
  /// **'Derive key from #name — no QR needed'**
  String get deriveKeyFromName;

  /// No description provided for @publicChannelName.
  ///
  /// In en, this message translates to:
  /// **'#public'**
  String get publicChannelName;

  /// No description provided for @addViaLinkQr.
  ///
  /// In en, this message translates to:
  /// **'Add via Link / QR Code'**
  String get addViaLinkQr;

  /// No description provided for @nameOrLink.
  ///
  /// In en, this message translates to:
  /// **'Name or Link'**
  String get nameOrLink;

  /// No description provided for @secretOrLink.
  ///
  /// In en, this message translates to:
  /// **'Secret or Link'**
  String get secretOrLink;

  /// No description provided for @meshcoreChannelAddPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'meshcore://channel/add?...'**
  String get meshcoreChannelAddPlaceholder;

  /// No description provided for @invalidChannelLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid channel link'**
  String get invalidChannelLink;

  /// No description provided for @invalidChannelLinkKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid channel link / key'**
  String get invalidChannelLinkKey;

  /// No description provided for @invalidTelemetryChannel.
  ///
  /// In en, this message translates to:
  /// **'Invalid telemetry channel'**
  String get invalidTelemetryChannel;

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Expected a download URL.'**
  String get invalidQrCode;

  /// No description provided for @noGroupChannelActive.
  ///
  /// In en, this message translates to:
  /// **'No group channel active'**
  String get noGroupChannelActive;

  /// No description provided for @noTelemetryChannelSet.
  ///
  /// In en, this message translates to:
  /// **'No telemetry channel set'**
  String get noTelemetryChannelSet;

  /// No description provided for @groupStatus.
  ///
  /// In en, this message translates to:
  /// **'Group status'**
  String get groupStatus;

  /// No description provided for @hexCharsOrBase64.
  ///
  /// In en, this message translates to:
  /// **'32 hex chars or base64'**
  String get hexCharsOrBase64;

  /// No description provided for @channelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {name}'**
  String channelCreated(String name);

  /// No description provided for @channelJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined: {name}'**
  String channelJoined(String name);

  /// No description provided for @channelAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {name}'**
  String channelAdded(String name);

  /// No description provided for @directMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get directMessage;

  /// No description provided for @directMessagesDisabledForRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Direct messages are disabled for repeaters'**
  String get directMessagesDisabledForRepeaters;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @copyMessageText.
  ///
  /// In en, this message translates to:
  /// **'Copy message text'**
  String get copyMessageText;

  /// No description provided for @notificationsMuted.
  ///
  /// In en, this message translates to:
  /// **'🔕 Muted'**
  String get notificationsMuted;

  /// No description provided for @notificationsSilent.
  ///
  /// In en, this message translates to:
  /// **'🔕 Silent'**
  String get notificationsSilent;

  /// No description provided for @channelNotifications.
  ///
  /// In en, this message translates to:
  /// **'Channel notifications'**
  String get channelNotifications;

  /// No description provided for @notificationModeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get notificationModeNormal;

  /// No description provided for @notificationModeNormalDesc.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get notificationModeNormalDesc;

  /// No description provided for @notificationModeSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get notificationModeSilent;

  /// No description provided for @notificationModeSilentDesc.
  ///
  /// In en, this message translates to:
  /// **'No alerts, badge still shows'**
  String get notificationModeSilentDesc;

  /// No description provided for @notificationModeMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get notificationModeMuted;

  /// No description provided for @notificationModeMutedDesc.
  ///
  /// In en, this message translates to:
  /// **'No alerts, no badge'**
  String get notificationModeMutedDesc;

  /// No description provided for @sortByMessageCount.
  ///
  /// In en, this message translates to:
  /// **'Sort by message count'**
  String get sortByMessageCount;

  /// No description provided for @sortByChannelNumber.
  ///
  /// In en, this message translates to:
  /// **'Sort by channel number'**
  String get sortByChannelNumber;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @mapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map settings'**
  String get mapSettings;

  /// No description provided for @mapType.
  ///
  /// In en, this message translates to:
  /// **'Map type'**
  String get mapType;

  /// No description provided for @offlineMaps.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps'**
  String get offlineMaps;

  /// No description provided for @manageOfflineMaps.
  ///
  /// In en, this message translates to:
  /// **'Manage Offline Maps'**
  String get manageOfflineMaps;

  /// No description provided for @downloadMapArea.
  ///
  /// In en, this message translates to:
  /// **'Download Map Area'**
  String get downloadMapArea;

  /// No description provided for @noOfflineMapsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'No offline maps downloaded'**
  String get noOfflineMapsDownloaded;

  /// No description provided for @removesDownloadedTilesAndMetadata.
  ///
  /// In en, this message translates to:
  /// **'Removes downloaded tiles and metadata'**
  String get removesDownloadedTilesAndMetadata;

  /// No description provided for @importedMaps.
  ///
  /// In en, this message translates to:
  /// **'Imported Maps'**
  String get importedMaps;

  /// No description provided for @manageImportedMaps.
  ///
  /// In en, this message translates to:
  /// **'Manage Imported Maps'**
  String get manageImportedMaps;

  /// No description provided for @importMap.
  ///
  /// In en, this message translates to:
  /// **'Import Map'**
  String get importMap;

  /// No description provided for @importMapFile.
  ///
  /// In en, this message translates to:
  /// **'Import map file'**
  String get importMapFile;

  /// No description provided for @centerOnMap.
  ///
  /// In en, this message translates to:
  /// **'Center on map'**
  String get centerOnMap;

  /// No description provided for @noMembersOnMap.
  ///
  /// In en, this message translates to:
  /// **'No members on map'**
  String get noMembersOnMap;

  /// No description provided for @showContactPaths.
  ///
  /// In en, this message translates to:
  /// **'Show Contact Paths'**
  String get showContactPaths;

  /// No description provided for @showTrackedUserNames.
  ///
  /// In en, this message translates to:
  /// **'Show Tracked User Names'**
  String get showTrackedUserNames;

  /// No description provided for @showWaypointAndRouteNames.
  ///
  /// In en, this message translates to:
  /// **'Show Waypoint & Route Names'**
  String get showWaypointAndRouteNames;

  /// No description provided for @locationSharingOff.
  ///
  /// In en, this message translates to:
  /// **'Location sharing off'**
  String get locationSharingOff;

  /// No description provided for @locationSharingOn.
  ///
  /// In en, this message translates to:
  /// **'Location sharing on'**
  String get locationSharingOn;

  /// No description provided for @locationSharingIsOff.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is off'**
  String get locationSharingIsOff;

  /// No description provided for @stopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing?'**
  String get stopSharing;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} coming soon'**
  String featureComingSoon(String feature);

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'{name} ({id}) • hops:{hops} • heard:{heard}'**
  String contactInfo(String name, String id, String hops, String heard);

  /// No description provided for @manageWaypointsAndRoutes.
  ///
  /// In en, this message translates to:
  /// **'Manage Waypoints & Routes'**
  String get manageWaypointsAndRoutes;

  /// No description provided for @waypointName.
  ///
  /// In en, this message translates to:
  /// **'Waypoint Name'**
  String get waypointName;

  /// No description provided for @waypointType.
  ///
  /// In en, this message translates to:
  /// **'Waypoint Type'**
  String get waypointType;

  /// No description provided for @addWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Add Waypoint'**
  String get addWaypoint;

  /// No description provided for @editWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Edit Waypoint'**
  String get editWaypoint;

  /// No description provided for @deleteWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Delete Waypoint'**
  String get deleteWaypoint;

  /// No description provided for @createWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Create Waypoint'**
  String get createWaypoint;

  /// No description provided for @navigateToWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Waypoint'**
  String get navigateToWaypoint;

  /// No description provided for @navigateTo.
  ///
  /// In en, this message translates to:
  /// **'Navigate to'**
  String get navigateTo;

  /// No description provided for @cancelNavigation.
  ///
  /// In en, this message translates to:
  /// **'Cancel navigation'**
  String get cancelNavigation;

  /// No description provided for @createRoute.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get createRoute;

  /// No description provided for @routeName.
  ///
  /// In en, this message translates to:
  /// **'Route Name'**
  String get routeName;

  /// No description provided for @noWaypointsOrRoutesYet.
  ///
  /// In en, this message translates to:
  /// **'No waypoints or routes yet.'**
  String get noWaypointsOrRoutesYet;

  /// No description provided for @waypointAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Waypoint already exists'**
  String get waypointAlreadyExists;

  /// No description provided for @addAtLeast2PointsForRoute.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 points for a route'**
  String get addAtLeast2PointsForRoute;

  /// No description provided for @waypointNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home, Trailhead, City Center'**
  String get waypointNameHint;

  /// No description provided for @routeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main Camp, Stand Alpha'**
  String get routeNameHint;

  /// No description provided for @channelNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Team Alpha, SAR Unit 5'**
  String get channelNameHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes…'**
  String get additionalNotes;

  /// No description provided for @shareWithTeamWhenSaved.
  ///
  /// In en, this message translates to:
  /// **'Share with team when saved'**
  String get shareWithTeamWhenSaved;

  /// No description provided for @shareViaMesh.
  ///
  /// In en, this message translates to:
  /// **'Share via Mesh'**
  String get shareViaMesh;

  /// No description provided for @shareWithOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Share with other apps'**
  String get shareWithOtherApps;

  /// No description provided for @shareEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get shareEllipsis;

  /// No description provided for @exportToGpx.
  ///
  /// In en, this message translates to:
  /// **'Export to GPX'**
  String get exportToGpx;

  /// No description provided for @importFromGpx.
  ///
  /// In en, this message translates to:
  /// **'Import from GPX'**
  String get importFromGpx;

  /// No description provided for @pleaseSelectGpxFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a .gpx file'**
  String get pleaseSelectGpxFile;

  /// No description provided for @saveToFileEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Save to file…'**
  String get saveToFileEllipsis;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @cancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get cancelSelection;

  /// No description provided for @exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get exportSelected;

  /// No description provided for @shareSelected.
  ///
  /// In en, this message translates to:
  /// **'Share selected'**
  String get shareSelected;

  /// No description provided for @wipeSelected.
  ///
  /// In en, this message translates to:
  /// **'Wipe Selected'**
  String get wipeSelected;

  /// No description provided for @deleteAllLocal.
  ///
  /// In en, this message translates to:
  /// **'Delete All Local'**
  String get deleteAllLocal;

  /// No description provided for @deleteAllReceived.
  ///
  /// In en, this message translates to:
  /// **'Delete All Received'**
  String get deleteAllReceived;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @deletedWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} waypoint(s)'**
  String deletedWaypoints(int count);

  /// No description provided for @importedWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} waypoint(s)'**
  String importedWaypoints(int count);

  /// No description provided for @savedToPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedToPath(String path);

  /// No description provided for @exportFailedError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailedError(String error);

  /// No description provided for @importFailedError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailedError(String error);

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalCount(int count);

  /// No description provided for @localCount.
  ///
  /// In en, this message translates to:
  /// **'Local: {count}'**
  String localCount(int count);

  /// No description provided for @receivedCount.
  ///
  /// In en, this message translates to:
  /// **'Received: {count}'**
  String receivedCount(int count);

  /// No description provided for @routesCount.
  ///
  /// In en, this message translates to:
  /// **'Routes: {count}'**
  String routesCount(int count);

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @continueToPermissions.
  ///
  /// In en, this message translates to:
  /// **'Continue to permissions'**
  String get continueToPermissions;

  /// No description provided for @storage2.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage2;

  /// No description provided for @wipe.
  ///
  /// In en, this message translates to:
  /// **'Wipe'**
  String get wipe;

  /// No description provided for @wipeLocalData.
  ///
  /// In en, this message translates to:
  /// **'Wipe Local Data'**
  String get wipeLocalData;

  /// No description provided for @dataWipedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data wiped successfully'**
  String get dataWipedSuccessfully;

  /// No description provided for @wipingData.
  ///
  /// In en, this message translates to:
  /// **'Wiping data...'**
  String get wipingData;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @debugLogsTitleWithCount.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs ({count})'**
  String debugLogsTitleWithCount(int count);

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @clearsFromFirmwareAndLocalDatabase.
  ///
  /// In en, this message translates to:
  /// **'Clears from firmware and local database'**
  String get clearsFromFirmwareAndLocalDatabase;

  /// No description provided for @thisWillStopTheConfigServer.
  ///
  /// In en, this message translates to:
  /// **'This will stop the config server. '**
  String get thisWillStopTheConfigServer;

  /// No description provided for @failedToApplySettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply settings. If enabling autonomous, ensure companion GPS is enabled and has a valid fix.'**
  String get failedToApplySettings;

  /// No description provided for @noGroupStatusChannel.
  ///
  /// In en, this message translates to:
  /// **'No group channel active'**
  String get noGroupStatusChannel;

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @waypointsAndRoutes.
  ///
  /// In en, this message translates to:
  /// **'Waypoints & Routes'**
  String get waypointsAndRoutes;

  /// No description provided for @channelsWithPrivateCount.
  ///
  /// In en, this message translates to:
  /// **'Channels ({count} private)'**
  String channelsWithPrivateCount(int count);

  /// No description provided for @waypointsAndRoutesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Waypoints & Routes ({count})'**
  String waypointsAndRoutesWithCount(int count);

  /// No description provided for @offlineMapsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps ({count} areas)'**
  String offlineMapsWithCount(int count);

  /// No description provided for @offlineMapAreas.
  ///
  /// In en, this message translates to:
  /// **'Offline Map Areas'**
  String get offlineMapAreas;

  /// No description provided for @overlayMaps.
  ///
  /// In en, this message translates to:
  /// **'Overlay Maps'**
  String get overlayMaps;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// No description provided for @clearAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Clear all failed: {error}'**
  String clearAllFailed(String error);

  /// No description provided for @failedToAddWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Failed to add waypoint: {error}'**
  String failedToAddWaypoint(String error);

  /// No description provided for @wipeFailed.
  ///
  /// In en, this message translates to:
  /// **'Wipe failed: {error}'**
  String wipeFailed(String error);

  /// No description provided for @channelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {name}'**
  String channelDeleted(String name);

  /// No description provided for @channelHash.
  ///
  /// In en, this message translates to:
  /// **'Hash: {hash}'**
  String channelHash(String hash);

  /// No description provided for @channelIndex.
  ///
  /// In en, this message translates to:
  /// **'Index: {index}'**
  String channelIndex(String index);

  /// No description provided for @joinChannelConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Join {tag}?'**
  String joinChannelConfirmation(String tag);

  /// No description provided for @lastHeard.
  ///
  /// In en, this message translates to:
  /// **'Last heard: {time}'**
  String lastHeard(String time);

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen: {time}'**
  String lastSeen(String time);

  /// No description provided for @hopCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Hop count: {count}'**
  String hopCountLabel(String count);

  /// No description provided for @inspectForwardingMode.
  ///
  /// In en, this message translates to:
  /// **'Inspect active forwarding mode and topology'**
  String get inspectForwardingMode;

  /// No description provided for @forwardingPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key: {key}'**
  String forwardingPublicKey(String key);

  /// No description provided for @forwardingDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct: {value}'**
  String forwardingDirect(String value);

  /// No description provided for @forwardingRepeater.
  ///
  /// In en, this message translates to:
  /// **'Repeater: {value}'**
  String forwardingRepeater(String value);

  /// No description provided for @forwardingOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range: {value}'**
  String forwardingOutOfRange(String value);

  /// No description provided for @forwardingMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String forwardingMode(String mode);

  /// No description provided for @forwardingLastMaxHops.
  ///
  /// In en, this message translates to:
  /// **'Last max hops: {hops}'**
  String forwardingLastMaxHops(String hops);

  /// No description provided for @forwardingLastTrigger.
  ///
  /// In en, this message translates to:
  /// **'Last trigger: {trigger}'**
  String forwardingLastTrigger(String trigger);

  /// No description provided for @forwardingLastApplied.
  ///
  /// In en, this message translates to:
  /// **'Last applied: {time}'**
  String forwardingLastApplied(String time);

  /// No description provided for @forwardingLastError.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String forwardingLastError(String error);

  /// No description provided for @forwardingCandidateReason.
  ///
  /// In en, this message translates to:
  /// **'Candidate reason: {reason}'**
  String forwardingCandidateReason(String reason);

  /// No description provided for @zoomRange.
  ///
  /// In en, this message translates to:
  /// **'Zoom range: {min}–{max}'**
  String zoomRange(String min, String max);

  /// No description provided for @minDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'Min distance: {distance}m'**
  String minDistanceMeters(String distance);

  /// No description provided for @mapProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider: {label}'**
  String mapProviderLabel(String label);

  /// No description provided for @intervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Interval: {seconds}s'**
  String intervalSeconds(String seconds);

  /// No description provided for @companionBattery.
  ///
  /// In en, this message translates to:
  /// **'Companion: {battery}'**
  String companionBattery(String battery);

  /// No description provided for @phoneBattery.
  ///
  /// In en, this message translates to:
  /// **'Phone: {battery}'**
  String phoneBattery(String battery);

  /// No description provided for @couldNotConfigureCompanionGps.
  ///
  /// In en, this message translates to:
  /// **'Could not configure companion GPS — no GPS hardware?'**
  String get couldNotConfigureCompanionGps;

  /// No description provided for @scanChannelQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Channel QR'**
  String get scanChannelQr;

  /// No description provided for @scanConfigQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Config QR Code'**
  String get scanConfigQrCode;

  /// No description provided for @wipePermanentDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the selected data.'**
  String get wipePermanentDeleteWarning;

  /// No description provided for @tileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tiles'**
  String tileCount(int count);

  /// No description provided for @channelTypePublic.
  ///
  /// In en, this message translates to:
  /// **'Type: Public'**
  String get channelTypePublic;

  /// No description provided for @channelTypePrivate.
  ///
  /// In en, this message translates to:
  /// **'Type: Private'**
  String get channelTypePrivate;

  /// No description provided for @publicChannel.
  ///
  /// In en, this message translates to:
  /// **'Public Channel'**
  String get publicChannel;

  /// No description provided for @privateChannel.
  ///
  /// In en, this message translates to:
  /// **'Private Channel'**
  String get privateChannel;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @keepScreenOnEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled — screen stays on and shows over lock screen'**
  String get keepScreenOnEnabled;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @disconnectDevice.
  ///
  /// In en, this message translates to:
  /// **'Disconnect device'**
  String get disconnectDevice;

  /// No description provided for @advert.
  ///
  /// In en, this message translates to:
  /// **'Advert'**
  String get advert;

  /// No description provided for @firmwareStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get firmwareStock;

  /// No description provided for @firmwareCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get firmwareCustom;

  /// No description provided for @firmwareInfo.
  ///
  /// In en, this message translates to:
  /// **'FW: {type} • {forwarding} • {autonomous}'**
  String firmwareInfo(String type, String forwarding, String autonomous);

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'ID: {address}'**
  String deviceId(String address);

  /// No description provided for @batteryVoltage.
  ///
  /// In en, this message translates to:
  /// **'Battery: {voltage}V'**
  String batteryVoltage(String voltage);

  /// No description provided for @idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// No description provided for @syncingContacts.
  ///
  /// In en, this message translates to:
  /// **'Syncing Contacts...'**
  String get syncingContacts;

  /// No description provided for @syncingChannels.
  ///
  /// In en, this message translates to:
  /// **'Syncing Channels...'**
  String get syncingChannels;

  /// No description provided for @syncingMessages.
  ///
  /// In en, this message translates to:
  /// **'Syncing Messages...'**
  String get syncingMessages;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync Complete'**
  String get syncComplete;

  /// No description provided for @logCategorySync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get logCategorySync;

  /// No description provided for @logCategoryBle.
  ///
  /// In en, this message translates to:
  /// **'BLE'**
  String get logCategoryBle;

  /// No description provided for @logCategoryTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get logCategoryTelemetry;

  /// No description provided for @logCategoryForwarding.
  ///
  /// In en, this message translates to:
  /// **'Forwarding'**
  String get logCategoryForwarding;

  /// No description provided for @logCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get logCategoryGeneral;

  /// No description provided for @autoScrollOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll on'**
  String get autoScrollOn;

  /// No description provided for @autoScrollOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll off'**
  String get autoScrollOff;

  /// No description provided for @sharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Sharing location'**
  String get sharingLocation;

  /// No description provided for @locationSharingEnabledNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Location sharing enabled (not connected)'**
  String get locationSharingEnabledNotConnected;

  /// No description provided for @campModeForwardingActive.
  ///
  /// In en, this message translates to:
  /// **'Camp mode - forwarding active ({hops, plural, one{1 hop} other{{hops} hops}})'**
  String campModeForwardingActive(int hops);

  /// No description provided for @policyEngineForwardingActive.
  ///
  /// In en, this message translates to:
  /// **'Policy engine: forwarding active ({hops, plural, one{1 hop} other{{hops} hops}})'**
  String policyEngineForwardingActive(int hops);

  /// No description provided for @forwardingModeCamp.
  ///
  /// In en, this message translates to:
  /// **'Forwarding mode: camp'**
  String get forwardingModeCamp;

  /// No description provided for @defaultRouting.
  ///
  /// In en, this message translates to:
  /// **'Default routing'**
  String get defaultRouting;

  /// No description provided for @typeAMessageToChannel.
  ///
  /// In en, this message translates to:
  /// **'Type a message to {channel}...'**
  String typeAMessageToChannel(String channel);

  /// No description provided for @noMessagesInChannel.
  ///
  /// In en, this message translates to:
  /// **'No messages in this channel'**
  String get noMessagesInChannel;

  /// No description provided for @beFirstToStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Be the first to start the conversation'**
  String get beFirstToStartConversation;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @sendMessageToStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start the conversation'**
  String get sendMessageToStartConversation;

  /// No description provided for @directConnection.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get directConnection;

  /// No description provided for @hopCount.
  ///
  /// In en, this message translates to:
  /// **'{hops, plural, one{1 hop} other{{hops} hops}}'**
  String hopCount(int hops);

  /// No description provided for @noMapMarkersOnly.
  ///
  /// In en, this message translates to:
  /// **'No Map (markers only)'**
  String get noMapMarkersOnly;

  /// No description provided for @filterContacts.
  ///
  /// In en, this message translates to:
  /// **'Filter contacts'**
  String get filterContacts;

  /// No description provided for @filterEndNodes.
  ///
  /// In en, this message translates to:
  /// **'End Nodes'**
  String get filterEndNodes;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filterHasLocation.
  ///
  /// In en, this message translates to:
  /// **'Has location'**
  String get filterHasLocation;

  /// No description provided for @filterNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get filterNoLocation;

  /// No description provided for @filterRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get filterRepeaters;

  /// No description provided for @filterRoomServers.
  ///
  /// In en, this message translates to:
  /// **'Room Servers'**
  String get filterRoomServers;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get sortByName;

  /// No description provided for @sortByLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Sort by last seen'**
  String get sortByLastSeen;

  /// No description provided for @sortByFavorites.
  ///
  /// In en, this message translates to:
  /// **'Sort by favorites'**
  String get sortByFavorites;

  /// No description provided for @noContactsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No contacts match the current filter'**
  String get noContactsMatchFilter;

  /// No description provided for @noContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts'**
  String get noContacts;

  /// No description provided for @connectToDeviceToSeeContacts.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device and sync to see contacts'**
  String get connectToDeviceToSeeContacts;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @repeater.
  ///
  /// In en, this message translates to:
  /// **'Repeater'**
  String get repeater;

  /// No description provided for @repeaterLabel.
  ///
  /// In en, this message translates to:
  /// **'REPEATER'**
  String get repeaterLabel;

  /// No description provided for @locationCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Location: {lat}, {lon}'**
  String locationCoordinates(String lat, String lon);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get deleteContact;

  /// No description provided for @contactDeletedName.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String contactDeletedName(String name);

  /// No description provided for @autoPurgeContacts.
  ///
  /// In en, this message translates to:
  /// **'Auto-purge contacts'**
  String get autoPurgeContacts;

  /// No description provided for @autoPurgeContactsDays.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{day} other{days}}'**
  String autoPurgeContactsDays(int count);

  /// No description provided for @autoPurgeContactsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get autoPurgeContactsNever;

  /// No description provided for @deleteAllContacts.
  ///
  /// In en, this message translates to:
  /// **'Delete all contacts'**
  String get deleteAllContacts;

  /// No description provided for @deleteAllContactsConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all contacts from this device and from the companion. Contacts will reappear as nodes are heard on the mesh.'**
  String get deleteAllContactsConfirm;

  /// No description provided for @deleteAllChannels.
  ///
  /// In en, this message translates to:
  /// **'Delete all channels'**
  String get deleteAllChannels;

  /// No description provided for @deleteAllChannelsConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all private channels from this device and from the companion. The public channel will not be affected.'**
  String get deleteAllChannelsConfirm;

  /// No description provided for @channelsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{channel} other{channels}} deleted'**
  String channelsDeleted(int count);

  /// No description provided for @deleteAllContactsFavoritesNote.
  ///
  /// In en, this message translates to:
  /// **'Favorites will not be deleted.'**
  String get deleteAllContactsFavoritesNote;

  /// No description provided for @contactsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{contact} other{contacts}} deleted'**
  String contactsDeleted(int count);

  /// No description provided for @android.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get android;

  /// No description provided for @locationEnabledBackground.
  ///
  /// In en, this message translates to:
  /// **'Enabled — location updates continue in background'**
  String get locationEnabledBackground;

  /// No description provided for @trackingChannelIndex.
  ///
  /// In en, this message translates to:
  /// **'Tracking channel index: {index} • timeout: 12h • visible users: {count}'**
  String trackingChannelIndex(String index, int count);

  /// No description provided for @trackingChannelNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Tracking channel not configured'**
  String get trackingChannelNotConfigured;

  /// No description provided for @teamMembersCanNoLongerDownload.
  ///
  /// In en, this message translates to:
  /// **'Team members will no longer be able to download.'**
  String get teamMembersCanNoLongerDownload;

  /// Divider label shown above the first unread message in a chat
  ///
  /// In en, this message translates to:
  /// **'Unread Messages'**
  String get unreadMessages;

  /// Shows which channel location telemetry will be shared on
  ///
  /// In en, this message translates to:
  /// **'Will share on: {channel}'**
  String willShareOnChannel(String channel);

  /// Shown when no telemetry channel has been picked
  ///
  /// In en, this message translates to:
  /// **'No channel selected'**
  String get noChannelSelected;

  /// Hint shown when disconnected on the location tracking card
  ///
  /// In en, this message translates to:
  /// **'Connect to a device to select a channel.'**
  String get connectToDeviceToSelectChannel;

  /// Empty state title on the channels list
  ///
  /// In en, this message translates to:
  /// **'No channels'**
  String get noChannels;

  /// Empty state body on the channels list
  ///
  /// In en, this message translates to:
  /// **'Connect to a device and sync to see channels'**
  String get connectToDeviceToSeeChannels;

  /// No description provided for @bluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get bluetooth;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// Intro paragraph on the first-run permissions screen
  ///
  /// In en, this message translates to:
  /// **'To connect to your mesh radio and share messages, MeshCore TEAM needs access to:'**
  String get permissionsIntro;

  /// No description provided for @permissionBluetoothReason.
  ///
  /// In en, this message translates to:
  /// **'Connect to your mesh radio'**
  String get permissionBluetoothReason;

  /// No description provided for @permissionLocationReason.
  ///
  /// In en, this message translates to:
  /// **'Required for maps: navigate and share your location with your team.'**
  String get permissionLocationReason;

  /// No description provided for @permissionNotificationsReason.
  ///
  /// In en, this message translates to:
  /// **'Alert you when messages arrive'**
  String get permissionNotificationsReason;

  /// No description provided for @permissionBackgroundReason.
  ///
  /// In en, this message translates to:
  /// **'Keep your mesh connection and tracking running in the background.'**
  String get permissionBackgroundReason;

  /// No description provided for @changePermissionsLaterHint.
  ///
  /// In en, this message translates to:
  /// **'You can change these later in system settings.'**
  String get changePermissionsLaterHint;

  /// No description provided for @requestingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Requesting permissions...'**
  String get requestingPermissions;

  /// No description provided for @permissionsRequiredToFunction.
  ///
  /// In en, this message translates to:
  /// **'MeshCore TEAM requires Bluetooth and Location permissions to function. Please grant these permissions to continue.'**
  String get permissionsRequiredToFunction;

  /// No description provided for @batteryOptimizationExplanation.
  ///
  /// In en, this message translates to:
  /// **'To keep your mesh connection active in the background, we recommend disabling battery optimization for this app.\n\nThis will allow the app to maintain a stable Bluetooth connection to your radio even when the screen is off.'**
  String get batteryOptimizationExplanation;

  /// Error shown when the permission request throws
  ///
  /// In en, this message translates to:
  /// **'Error requesting permissions: {error}'**
  String errorRequestingPermissions(String error);

  /// Error listing the permissions the user denied
  ///
  /// In en, this message translates to:
  /// **'Required permissions denied:\n{permissions}'**
  String requiredPermissionsDenied(String permissions);

  /// No description provided for @notificationChannelMessagesName.
  ///
  /// In en, this message translates to:
  /// **'Channel Messages'**
  String get notificationChannelMessagesName;

  /// No description provided for @notificationChannelMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for channel messages on the mesh network'**
  String get notificationChannelMessagesDescription;

  /// No description provided for @notificationChannelDirectName.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get notificationChannelDirectName;

  /// No description provided for @notificationChannelDirectDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for direct messages on the mesh network'**
  String get notificationChannelDirectDescription;

  /// No description provided for @notificationChannelWaypointsName.
  ///
  /// In en, this message translates to:
  /// **'Waypoint Notifications'**
  String get notificationChannelWaypointsName;

  /// No description provided for @notificationChannelWaypointsDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for received waypoints on the mesh network'**
  String get notificationChannelWaypointsDescription;

  /// Notification title for an incoming direct message
  ///
  /// In en, this message translates to:
  /// **'{sender} (Direct Message)'**
  String directMessageNotificationTitle(String sender);

  /// No description provided for @newMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get newMessagesTitle;

  /// Body of the batched sync notification
  ///
  /// In en, this message translates to:
  /// **'You have {count} {count, plural, =1{new message} other{new messages}}'**
  String newMessagesBody(int count);

  /// Notification title for a received waypoint
  ///
  /// In en, this message translates to:
  /// **'New Waypoint: {name}'**
  String newWaypointTitle(String name);

  /// No description provided for @newWaypoint.
  ///
  /// In en, this message translates to:
  /// **'New Waypoint'**
  String get newWaypoint;

  /// Notification body: waypoint type and who sent it
  ///
  /// In en, this message translates to:
  /// **'{type} from {creator}'**
  String waypointFromCreator(String type, String creator);

  /// No description provided for @channelsWillBeClearedFromFirmware.
  ///
  /// In en, this message translates to:
  /// **'Channels will be cleared from the connected companion firmware.'**
  String get channelsWillBeClearedFromFirmware;

  /// No description provided for @thisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get thisCannotBeUndone;

  /// No description provided for @bluetoothPermissionNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission not granted.'**
  String get bluetoothPermissionNotGranted;

  /// No description provided for @enableNearbyDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Nearby devices\" permission, then return to the app.'**
  String get enableNearbyDevicesHint;

  /// No description provided for @bluetoothIsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is Disabled'**
  String get bluetoothIsDisabled;

  /// No description provided for @turnOnBluetoothAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth and tap Retry.'**
  String get turnOnBluetoothAndRetry;

  /// No description provided for @tapScanToSearchForRadios.
  ///
  /// In en, this message translates to:
  /// **'Tap the scan button to search for MeshCore companion radios'**
  String get tapScanToSearchForRadios;

  /// No description provided for @meshDevice.
  ///
  /// In en, this message translates to:
  /// **'Mesh device'**
  String get meshDevice;

  /// No description provided for @companionSettings.
  ///
  /// In en, this message translates to:
  /// **'Companion Settings'**
  String get companionSettings;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @campModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Locks radio to camp-compatible presets and enables firmware repeat mode'**
  String get campModeDescription;

  /// No description provided for @smartForwardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Use app-managed smart forwarding while camp mode is active'**
  String get smartForwardingDescription;

  /// No description provided for @autonomousModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Configures firmware autonomous tracking. Uses values from Location Tracking settings.'**
  String get autonomousModeDescription;

  /// No description provided for @noGpsFixWarning.
  ///
  /// In en, this message translates to:
  /// **'No GPS fix yet. Telemetry will not be sent until the companion radio acquires a valid GPS position.'**
  String get noGpsFixWarning;

  /// Transmit power slider label
  ///
  /// In en, this message translates to:
  /// **'TX Power: {power} dBm (max {maxPower})'**
  String txPowerWithMax(int power, int maxPower);

  /// No description provided for @invalidFrequency.
  ///
  /// In en, this message translates to:
  /// **'Invalid frequency'**
  String get invalidFrequency;

  /// No description provided for @selectACampPreset.
  ///
  /// In en, this message translates to:
  /// **'Select a camp preset'**
  String get selectACampPreset;

  /// No description provided for @autonomousRejectedNoGpsUnit.
  ///
  /// In en, this message translates to:
  /// **'Firmware rejected autonomous enable (ERR 6). This device does not have a GPS unit.'**
  String get autonomousRejectedNoGpsUnit;

  /// No description provided for @autonomousVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify autonomous settings after write. Check connection and retry.'**
  String get autonomousVerifyFailed;

  /// No description provided for @autonomousSettingsDidNotStick.
  ///
  /// In en, this message translates to:
  /// **'Autonomous settings did not stick after write. Please retry.'**
  String get autonomousSettingsDidNotStick;

  /// No description provided for @failedToApplySettingsAutonomousHint.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply settings. If enabling autonomous, ensure companion GPS is enabled and has a valid fix.'**
  String get failedToApplySettingsAutonomousHint;

  /// No description provided for @failedToApplyRadioSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply radio settings.'**
  String get failedToApplyRadioSettings;

  /// No description provided for @sendAdvert.
  ///
  /// In en, this message translates to:
  /// **'Send Advert'**
  String get sendAdvert;

  /// Snackbar after a successful BLE connection
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String connectedToDevice(String device);

  /// Snackbar after a failed BLE connection
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {device}'**
  String failedToConnectToDevice(String device);

  /// No description provided for @copyContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy contact info'**
  String get copyContactInfo;

  /// No description provided for @contactInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Contact info copied'**
  String get contactInfoCopied;

  /// No description provided for @labelHash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get labelHash;

  /// No description provided for @labelBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get labelBattery;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @nodeTypeRepeater.
  ///
  /// In en, this message translates to:
  /// **'Repeater'**
  String get nodeTypeRepeater;

  /// No description provided for @nodeTypeRoomServer.
  ///
  /// In en, this message translates to:
  /// **'Room Server'**
  String get nodeTypeRoomServer;

  /// No description provided for @nodeTypeEndNode.
  ///
  /// In en, this message translates to:
  /// **'End Node'**
  String get nodeTypeEndNode;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Relative time, under an hour
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Relative time, under a day
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Relative time, a day or more
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @identityNameExplanation.
  ///
  /// In en, this message translates to:
  /// **'This name is how you will be identified on the mesh network.'**
  String get identityNameExplanation;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @failedToApplyName.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply name. Please try again.'**
  String get failedToApplyName;

  /// No description provided for @unknownContact.
  ///
  /// In en, this message translates to:
  /// **'Unknown Contact'**
  String get unknownContact;

  /// No description provided for @repeaterDirectMessagesDisabled.
  ///
  /// In en, this message translates to:
  /// **'This contact is a repeater. Direct messages are disabled.'**
  String get repeaterDirectMessagesDisabled;

  /// No description provided for @channelLinkPasswordWarning.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can join this private channel. Treat it like a password.'**
  String get channelLinkPasswordWarning;

  /// No description provided for @sameNameSameChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone who types the same name joins the same channel'**
  String get sameNameSameChannelHint;

  /// No description provided for @unnamedChannel.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Channel'**
  String get unnamedChannel;

  /// Latitude readout on the node detail sheet
  ///
  /// In en, this message translates to:
  /// **'Lat: {value}'**
  String latWithValue(String value);

  /// Longitude readout on the node detail sheet
  ///
  /// In en, this message translates to:
  /// **'Lon: {value}'**
  String lonWithValue(String value);

  /// No description provided for @hidePath.
  ///
  /// In en, this message translates to:
  /// **'Hide Path'**
  String get hidePath;

  /// No description provided for @showPath.
  ///
  /// In en, this message translates to:
  /// **'Show Path'**
  String get showPath;

  /// No description provided for @editRoute.
  ///
  /// In en, this message translates to:
  /// **'Edit Route'**
  String get editRoute;

  /// No description provided for @saveRoute.
  ///
  /// In en, this message translates to:
  /// **'Save Route'**
  String get saveRoute;

  /// No description provided for @routeColor.
  ///
  /// In en, this message translates to:
  /// **'Route Color'**
  String get routeColor;

  /// No description provided for @editRoutePoints.
  ///
  /// In en, this message translates to:
  /// **'Edit Route Points'**
  String get editRoutePoints;

  /// No description provided for @editRouteInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Route Info'**
  String get editRouteInfo;

  /// No description provided for @waypointSharedToMesh.
  ///
  /// In en, this message translates to:
  /// **'Waypoint shared to mesh'**
  String get waypointSharedToMesh;

  /// No description provided for @failedToShareWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Failed to share waypoint'**
  String get failedToShareWaypoint;

  /// No description provided for @deleteWaypointQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete waypoint?'**
  String get deleteWaypointQuestion;

  /// Confirmation body naming the waypoint
  ///
  /// In en, this message translates to:
  /// **'This will delete \"{name}\".'**
  String deleteWaypointNamed(String name);

  /// No description provided for @deleteWaypointsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete waypoints?'**
  String get deleteWaypointsQuestion;

  /// Confirmation body for a bulk waypoint delete
  ///
  /// In en, this message translates to:
  /// **'This will delete {count} {count, plural, =1{waypoint} other{waypoints}}.'**
  String deleteWaypointsCount(int count);

  /// No description provided for @deleteReceivedWaypointsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete received waypoints?'**
  String get deleteReceivedWaypointsQuestion;

  /// No description provided for @deleteReceivedWaypointsBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all received waypoints from the device.'**
  String get deleteReceivedWaypointsBody;

  /// No description provided for @deleteLocalWaypointsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete local waypoints?'**
  String get deleteLocalWaypointsQuestion;

  /// No description provided for @deleteLocalWaypointsBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all local waypoints you created on the device.'**
  String get deleteLocalWaypointsBody;

  /// Snackbar after sharing waypoints, all succeeded
  ///
  /// In en, this message translates to:
  /// **'Shared {count} {count, plural, =1{waypoint} other{waypoints}}'**
  String sharedWaypointsCount(int count);

  /// Snackbar after sharing waypoints, some failed
  ///
  /// In en, this message translates to:
  /// **'Shared {okCount}, failed {failCount}'**
  String sharedWaypointsPartial(int okCount, int failCount);

  /// No description provided for @routeModeTapToAddFirstPoint.
  ///
  /// In en, this message translates to:
  /// **'Route mode: tap map to add first point'**
  String get routeModeTapToAddFirstPoint;

  /// Route drawing hint with the running point count
  ///
  /// In en, this message translates to:
  /// **'Route mode: {count} {count, plural, =1{point} other{points}} (tap a point to move it)'**
  String routeModePointCount(int count);

  /// Route drawing hint while moving one point
  ///
  /// In en, this message translates to:
  /// **'Tap map to move point {index} (tap point again to cancel)'**
  String routeModeTapToMovePoint(int index);

  /// No description provided for @tapWaypointsToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap waypoints to select'**
  String get tapWaypointsToSelect;

  /// Multi-select header count
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String countSelected(int count);

  /// No description provided for @selectWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Select Waypoints'**
  String get selectWaypoints;

  /// No description provided for @importedWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Imported Waypoint'**
  String get importedWaypoint;

  /// No description provided for @saveGpxFile.
  ///
  /// In en, this message translates to:
  /// **'Save GPX file'**
  String get saveGpxFile;

  /// No description provided for @garminKmz.
  ///
  /// In en, this message translates to:
  /// **'Garmin KMZ'**
  String get garminKmz;

  /// No description provided for @garminKmzDescription.
  ///
  /// In en, this message translates to:
  /// **'Raster map tiles from a Garmin Custom Map archive'**
  String get garminKmzDescription;

  /// No description provided for @mbtilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Offline tile pyramid from QGIS, GDAL, or Mobile Atlas Creator'**
  String get mbtilesDescription;

  /// No description provided for @pleaseSelectMbtilesFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a .mbtiles file.'**
  String get pleaseSelectMbtilesFile;

  /// No description provided for @deleteMapQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete map?'**
  String get deleteMapQuestion;

  /// Confirmation body for deleting an imported overlay map
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{name}\" and its image files from the device.'**
  String deleteMapNamed(String name);

  /// No description provided for @noImportedMaps.
  ///
  /// In en, this message translates to:
  /// **'No imported maps'**
  String get noImportedMaps;

  /// No description provided for @noImportedMapsHint.
  ///
  /// In en, this message translates to:
  /// **'Import a Garmin-style KMZ file or an MBTiles archive to display a custom offline map on top of the base map.'**
  String get noImportedMapsHint;

  /// No description provided for @hideOnMap.
  ///
  /// In en, this message translates to:
  /// **'Hide on map'**
  String get hideOnMap;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get showOnMap;

  /// No description provided for @deleteOfflineMapQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete offline map?'**
  String get deleteOfflineMapQuestion;

  /// Confirmation body for deleting a downloaded map area
  ///
  /// In en, this message translates to:
  /// **'This will remove downloaded tiles for \"{name}\".'**
  String deleteOfflineMapNamed(String name);

  /// No description provided for @clearAllOfflineMapsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear all offline maps?'**
  String get clearAllOfflineMapsQuestion;

  /// No description provided for @clearAllOfflineMapsBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all downloaded offline map areas and their tiles.'**
  String get clearAllOfflineMapsBody;

  /// No description provided for @pleaseEnterAName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterAName;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// Offline map download error
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// Offline map download progress readout
  ///
  /// In en, this message translates to:
  /// **'Progress: {completed}/{total} (failed: {failed})'**
  String downloadProgress(int completed, int total, int failed);

  /// No description provided for @connectBeforeImportingConfig.
  ///
  /// In en, this message translates to:
  /// **'Connect to a companion device before importing. Channels must be registered with firmware.'**
  String get connectBeforeImportingConfig;

  /// No description provided for @importTeamConfigExplanation.
  ///
  /// In en, this message translates to:
  /// **'Import a team config from a local file or by scanning a QR code from a nearby device sharing over Wi-Fi.'**
  String get importTeamConfigExplanation;

  /// Warning listing overlay maps excluded from a shared config
  ///
  /// In en, this message translates to:
  /// **'Left out of the config because they are too large to share: {names}. Transfer the file directly instead.'**
  String omittedTooLargeToShare(String names);

  /// No description provided for @shareConfigWithoutInternet.
  ///
  /// In en, this message translates to:
  /// **'Share Config Without Internet'**
  String get shareConfigWithoutInternet;

  /// No description provided for @shareConfigHotspotExplanation.
  ///
  /// In en, this message translates to:
  /// **'Create a mobile hotspot on your device so team members can connect and download the config directly.'**
  String get shareConfigHotspotExplanation;

  /// No description provided for @mobileHotspot.
  ///
  /// In en, this message translates to:
  /// **'Mobile Hotspot'**
  String get mobileHotspot;

  /// No description provided for @iphoneOrIpad.
  ///
  /// In en, this message translates to:
  /// **'iPhone / iPad'**
  String get iphoneOrIpad;

  /// No description provided for @hotspotStepOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get hotspotStepOpenSettings;

  /// No description provided for @hotspotStepTapPersonalHotspot.
  ///
  /// In en, this message translates to:
  /// **'Tap Personal Hotspot'**
  String get hotspotStepTapPersonalHotspot;

  /// No description provided for @hotspotStepAllowOthersToJoin.
  ///
  /// In en, this message translates to:
  /// **'Turn on \"Allow Others to Join\"'**
  String get hotspotStepAllowOthersToJoin;

  /// No description provided for @hotspotStepShareNameAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Share the hotspot name and password with your team'**
  String get hotspotStepShareNameAndPassword;

  /// No description provided for @hotspotStepTapNetworkInternet.
  ///
  /// In en, this message translates to:
  /// **'Tap Network & Internet (or Connections)'**
  String get hotspotStepTapNetworkInternet;

  /// No description provided for @hotspotStepTapHotspotTethering.
  ///
  /// In en, this message translates to:
  /// **'Tap Hotspot & Tethering'**
  String get hotspotStepTapHotspotTethering;

  /// No description provided for @hotspotStepTurnOnWifiHotspot.
  ///
  /// In en, this message translates to:
  /// **'Turn on Wi-Fi Hotspot'**
  String get hotspotStepTurnOnWifiHotspot;

  /// No description provided for @hotspotStepEnableFromSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable your mobile hotspot from system settings'**
  String get hotspotStepEnableFromSystemSettings;

  /// No description provided for @connectToHotspotBeforeScanning.
  ///
  /// In en, this message translates to:
  /// **'Team members should connect to your hotspot Wi-Fi before scanning the QR code.'**
  String get connectToHotspotBeforeScanning;

  /// No description provided for @selectConfigToShare.
  ///
  /// In en, this message translates to:
  /// **'Select Config to Share'**
  String get selectConfigToShare;

  /// No description provided for @chooseTeamcfgFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a .teamcfg.zip file to share with your team.'**
  String get chooseTeamcfgFile;

  /// No description provided for @couldNotReadSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read selected file.'**
  String get couldNotReadSelectedFile;

  /// Error when a picked config file cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'Invalid config file: {error}'**
  String invalidConfigFile(String error);

  /// Error when the file picker itself fails
  ///
  /// In en, this message translates to:
  /// **'Error selecting file: {error}'**
  String errorSelectingFile(String error);

  /// No description provided for @configDetails.
  ///
  /// In en, this message translates to:
  /// **'Config Details'**
  String get configDetails;

  /// No description provided for @radioSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Radio Settings'**
  String get radioSettingsLabel;

  /// Config preview row label for channels
  ///
  /// In en, this message translates to:
  /// **'Channels ({count})'**
  String channelsWithCount(int count);

  /// No description provided for @mapTiles.
  ///
  /// In en, this message translates to:
  /// **'Map Tiles'**
  String get mapTiles;

  /// No description provided for @couldNotDetermineLocalIp.
  ///
  /// In en, this message translates to:
  /// **'Could not determine local IP address. Make sure your hotspot is enabled.'**
  String get couldNotDetermineLocalIp;

  /// Error when the local sharing server will not start
  ///
  /// In en, this message translates to:
  /// **'Failed to start server: {error}'**
  String failedToStartServer(String error);

  /// No description provided for @sharingConfig.
  ///
  /// In en, this message translates to:
  /// **'Sharing Config'**
  String get sharingConfig;

  /// No description provided for @teamMembersShould.
  ///
  /// In en, this message translates to:
  /// **'Team members should:'**
  String get teamMembersShould;

  /// No description provided for @shareStepConnectToHotspot.
  ///
  /// In en, this message translates to:
  /// **'Connect to your hotspot Wi-Fi'**
  String get shareStepConnectToHotspot;

  /// No description provided for @shareStepOpenImportFromQr.
  ///
  /// In en, this message translates to:
  /// **'Open MeshCore TEAM → Import Team Config → From QR Code'**
  String get shareStepOpenImportFromQr;

  /// No description provided for @shareStepScanQrToDownload.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to download'**
  String get shareStepScanQrToDownload;

  /// No description provided for @manualDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Manual download URL:'**
  String get manualDownloadUrl;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get starting;

  /// Body of the background-location permission dialog
  ///
  /// In en, this message translates to:
  /// **'MeshCore TEAM needs background location access to continue sharing your position with the mesh network when the app is minimized.\n\nThis allows location tracking and BLE communication to continue working in the background.'**
  String get backgroundLocationExplanation;

  /// No description provided for @meshConnectionChannelName.
  ///
  /// In en, this message translates to:
  /// **'Mesh Network Connection'**
  String get meshConnectionChannelName;

  /// No description provided for @meshConnectionChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Maintains mesh network connection in background'**
  String get meshConnectionChannelDescription;

  /// No description provided for @meshNetworkActive.
  ///
  /// In en, this message translates to:
  /// **'Mesh network active'**
  String get meshNetworkActive;

  /// No description provided for @meshNetwork.
  ///
  /// In en, this message translates to:
  /// **'Mesh network'**
  String get meshNetwork;

  /// No description provided for @meshNetworkReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Mesh network reconnecting'**
  String get meshNetworkReconnecting;

  /// No description provided for @meshNetworkConnecting.
  ///
  /// In en, this message translates to:
  /// **'Mesh network connecting'**
  String get meshNetworkConnecting;

  /// No description provided for @meshNetworkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Mesh network disconnected'**
  String get meshNetworkDisconnected;

  /// No description provided for @meshNetworkScanning.
  ///
  /// In en, this message translates to:
  /// **'Mesh network scanning'**
  String get meshNetworkScanning;

  /// No description provided for @meshNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Mesh network error'**
  String get meshNetworkError;

  /// No description provided for @connectingToCompanionDevice.
  ///
  /// In en, this message translates to:
  /// **'Connecting to companion device...'**
  String get connectingToCompanionDevice;

  /// Foreground notification body while reconnecting
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to {device}...'**
  String reconnectingToDevice(String device);

  /// No description provided for @establishingConnection.
  ///
  /// In en, this message translates to:
  /// **'Establishing connection...'**
  String get establishingConnection;

  /// No description provided for @deviceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get deviceDisconnected;

  /// No description provided for @searchingForDevices.
  ///
  /// In en, this message translates to:
  /// **'Searching for devices...'**
  String get searchingForDevices;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @maxChannelsReachedJoin.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of channels reached. Delete an existing channel before joining a new one.'**
  String get maxChannelsReachedJoin;

  /// No description provided for @maxChannelsReachedCreate.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of channels reached. Delete an existing channel before creating a new one.'**
  String get maxChannelsReachedCreate;

  /// Firmware rejected a channel registration
  ///
  /// In en, this message translates to:
  /// **'Failed to register channel with firmware (error {code})'**
  String failedToRegisterChannel(String code);

  /// Firmware rejected a channel delete
  ///
  /// In en, this message translates to:
  /// **'Failed to delete channel from companion (error {code})'**
  String failedToDeleteChannelFromCompanion(String code);

  /// No description provided for @kmzNoDocKml.
  ///
  /// In en, this message translates to:
  /// **'No doc.kml found in KMZ file. Is this a valid Garmin Custom Map?'**
  String get kmzNoDocKml;

  /// No description provided for @kmzNoGroundOverlay.
  ///
  /// In en, this message translates to:
  /// **'No GroundOverlay elements found in doc.kml. This KMZ does not contain raster map overlays.'**
  String get kmzNoGroundOverlay;

  /// No description provided for @kmzNoUsableTiles.
  ///
  /// In en, this message translates to:
  /// **'Could not extract any usable image tiles from the KMZ.'**
  String get kmzNoUsableTiles;

  /// No description provided for @mbtilesVectorNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This is a vector MBTiles file. Only raster MBTiles (PNG, JPG, or WebP tiles) can be displayed.'**
  String get mbtilesVectorNotSupported;

  /// No description provided for @nothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get nothingNew;

  /// Summary of what a team config import brought in
  ///
  /// In en, this message translates to:
  /// **'Imported {items}'**
  String importedItems(String items);

  /// No description provided for @packingTiles.
  ///
  /// In en, this message translates to:
  /// **'Packing tiles'**
  String get packingTiles;

  /// No description provided for @applyingRadioSettings.
  ///
  /// In en, this message translates to:
  /// **'Applying radio settings'**
  String get applyingRadioSettings;

  /// No description provided for @importingChannels.
  ///
  /// In en, this message translates to:
  /// **'Importing channels'**
  String get importingChannels;

  /// No description provided for @importingWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Importing waypoints'**
  String get importingWaypoints;

  /// No description provided for @importingTiles.
  ///
  /// In en, this message translates to:
  /// **'Importing tiles'**
  String get importingTiles;

  /// No description provided for @importingOverlayMaps.
  ///
  /// In en, this message translates to:
  /// **'Importing overlay maps'**
  String get importingOverlayMaps;

  /// No description provided for @meshUser.
  ///
  /// In en, this message translates to:
  /// **'Mesh User'**
  String get meshUser;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Channel count fragment in the import summary
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{channel} other{channels}}'**
  String countChannels(int count);

  /// Waypoint count fragment in the import summary
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{waypoint} other{waypoints}}'**
  String countWaypoints(int count);

  /// Tile count fragment in the import summary
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{tile} other{tiles}}'**
  String countTiles(int count);

  /// Overlay map count fragment in the import summary
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{overlay map} other{overlay maps}}'**
  String countOverlayMaps(int count);

  /// No description provided for @radioSettingsItem.
  ///
  /// In en, this message translates to:
  /// **'radio settings'**
  String get radioSettingsItem;

  /// Import summary that also lists skipped items
  ///
  /// In en, this message translates to:
  /// **'{imported} (skipped {skipped})'**
  String importedWithSkipped(String imported, String skipped);

  /// No description provided for @heardNearby.
  ///
  /// In en, this message translates to:
  /// **'Heard nearby ({count})'**
  String heardNearby(int count);

  /// No description provided for @heardNearbyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Devices your radio heard but did not add. Team members are added for you.'**
  String get heardNearbyExplanation;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @contactAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String contactAdded(String name);

  /// No description provided for @contactAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add {name}'**
  String contactAddFailed(String name);

  /// No description provided for @roomServer.
  ///
  /// In en, this message translates to:
  /// **'Room server'**
  String get roomServer;

  /// No description provided for @sensor.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get sensor;

  /// No description provided for @teamChannel.
  ///
  /// In en, this message translates to:
  /// **'Team channel'**
  String get teamChannel;

  /// No description provided for @teamChannelExplanation.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone with its history, even if you change radio.'**
  String get teamChannelExplanation;

  /// No description provided for @notOnRadio.
  ///
  /// In en, this message translates to:
  /// **'Not on this radio'**
  String get notOnRadio;

  /// No description provided for @addChannelToRadio.
  ///
  /// In en, this message translates to:
  /// **'Add to radio?'**
  String get addChannelToRadio;

  /// No description provided for @addChannelToRadioExplanation.
  ///
  /// In en, this message translates to:
  /// **'This channel has to be on your radio to send messages or use it for tracking.'**
  String get addChannelToRadioExplanation;

  /// No description provided for @addChannelToRadioNoSlots.
  ///
  /// In en, this message translates to:
  /// **'Your radio has no free channel slots. Delete a channel on the radio first.'**
  String get addChannelToRadioNoSlots;

  /// No description provided for @addedChannelToRadio.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to your radio'**
  String addedChannelToRadio(String name);

  /// No description provided for @failedToAddChannel.
  ///
  /// In en, this message translates to:
  /// **'Could not add the channel to your radio'**
  String get failedToAddChannel;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get teamName;

  /// No description provided for @teamNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Set your name'**
  String get teamNamePrompt;

  /// No description provided for @teamNameSaveExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your team will see this name. Only people on your team channel can see it.'**
  String get teamNameSaveExplanation;

  /// No description provided for @teamNameSkipExplanation.
  ///
  /// In en, this message translates to:
  /// **'If you skip this, your team will see your radio name, which everyone on the mesh can see.'**
  String get teamNameSkipExplanation;

  /// No description provided for @teamNameChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can set or change your team name later in Settings.'**
  String get teamNameChangeLater;

  /// No description provided for @teamNameUsingRadioName.
  ///
  /// In en, this message translates to:
  /// **'Using radio name ({name})'**
  String teamNameUsingRadioName(String name);

  /// No description provided for @radioNameExplanation.
  ///
  /// In en, this message translates to:
  /// **'This name is visible to everyone on the mesh, including people outside your team. Consider an anonymous name.'**
  String get radioNameExplanation;

  /// No description provided for @teamNameSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Name (hidden outside your team)'**
  String get teamNameSettingsTitle;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @hideNonTeam.
  ///
  /// In en, this message translates to:
  /// **'Hide all but team channels and contacts'**
  String get hideNonTeam;

  /// No description provided for @deleteChannelNeedsRadio.
  ///
  /// In en, this message translates to:
  /// **'This channel is stored on your radio. Connect to the radio to delete it.'**
  String get deleteChannelNeedsRadio;

  /// No description provided for @trackingChannelPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share your location on'**
  String get trackingChannelPrompt;

  /// No description provided for @trackingNeedsPrivateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create a private channel first. Your location is only shared on a private channel.'**
  String get trackingNeedsPrivateChannel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
