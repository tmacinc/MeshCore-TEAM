// Copyright (c) 2026 tmacinc
// Licensed under CC BY-NC-SA 4.0
// http://creativecommons.org/licenses/by-nc-sa/4.0/
//
// This file is part of TEAM-Flutter.
// Non-commercial use only. See LICENSE file for details.

import 'package:meshcore_team/models/app_settings.dart';

class MapTileProviderOption {
  final String id;
  final String label;
  final String urlTemplate;
  final List<String> subdomains;

  const MapTileProviderOption({
    required this.id,
    required this.label,
    required this.urlTemplate,
    this.subdomains = const <String>[],
  });
}

const List<MapTileProviderOption> kMapTileProviderOptions = [
  MapTileProviderOption(
    id: MapProvider.mapnik,
    label: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  MapTileProviderOption(
    id: MapProvider.topo,
    label: 'OpenTopoMap',
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
  ),
  MapTileProviderOption(
    id: MapProvider.usgsSat,
    label: 'USGS Satellite',
    urlTemplate:
        'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryOnly/MapServer/tile/{z}/{y}/{x}',
  ),
  MapTileProviderOption(
    id: MapProvider.usgsTopo,
    label: 'USGS Topographic',
    urlTemplate:
        'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}',
  ),
  MapTileProviderOption(
    id: MapProvider.hot,
    label: 'Humanitarian',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
  ),
  MapTileProviderOption(
    id: MapProvider.esriSat,
    label: 'ESRI Satellite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  ),
  MapTileProviderOption(
    id: MapProvider.carto,
    label: 'Carto Voyager',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c', 'd'],
  ),
];

String normalizeMapProviderId(String providerId) {
  // Keep legacy 'satellite' working.
  if (providerId == MapProvider.satellite) {
    return MapProvider.esriSat;
  }

  if (providerId == MapProvider.openTopoLegacy) {
    return MapProvider.topo;
  }
  if (providerId == MapProvider.usgsSatelliteLegacy) {
    return MapProvider.usgsSat;
  }
  if (providerId == MapProvider.humanitarianLegacy) {
    return MapProvider.hot;
  }
  if (providerId == MapProvider.esriSatelliteLegacy) {
    return MapProvider.esriSat;
  }
  if (providerId == MapProvider.cartoVoyagerLegacy) {
    return MapProvider.carto;
  }

  return providerId;
}

MapTileProviderOption tileProviderForId(String providerId) {
  final normalized = normalizeMapProviderId(providerId);
  return kMapTileProviderOptions.firstWhere(
    (o) => o.id == normalized,
    orElse: () => kMapTileProviderOptions.firstWhere(
      (o) => o.id == MapProvider.mapnik,
    ),
  );
}
