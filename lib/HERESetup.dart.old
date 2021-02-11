/*
 * Copyright (C) 2019-2020 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:WaliedCheetos_DTPOC/FetchData.dart';
import 'package:WaliedCheetos_DTPOC/appConfig.dart';

import 'package:maps_curved_line/maps_curved_line.dart';
// import 'package:latlng/latlng.dart';

// class CONFIG {
//   String appTitle = 'WaliedCheetos - POC for DT';
//   double initialLAT = 25.40279;
//   double initialLNG = 55.44262;
//   // double initialLAT = 25.19893;
//   // double initialLNG = 55.27991;
//   MapCameraOrientationUpdate mapCameraOrientationUpdate;
//   double initialDistanceToEarthInMeters = 8000;
//   String prefix = 'WaliedCheetos: ';
// }

class HERESetup {
  BuildContext _context;
  // CONFIG _config = CONFIG();
  appConfig _appConfig = appConfig();
  FetchData _fetchData = new FetchData();
  HereMapController _hereMapController;
  SearchEngine _searchEngine;
  GeoPolygon _geoPolygonAjman;
  MapPolygon _mapPolygonAjman;
  MapImage _mapImageMarker;
  MapMarker _mapMarker;
  List<MapMarker> _mapMarkerList = [];
  List<MapPolyline> _mapPolylineList = [];
  TextEditingController _textEditingController;

  HERESetup(BuildContext context, HereMapController hereMapController,
      TextEditingController textEditingController) {
    // HERESetup(BuildContext context, HereMapController hereMapController) {
    _textEditingController = textEditingController;
    _context = context;
    _hereMapController = hereMapController;

    _hereMapController.camera.lookAtPointWithDistance(
        GeoCoordinates(_appConfig.initialLAT, _appConfig.initialLNG),
        _appConfig.initialDistanceToEarthInMeters);

    _setupPanGesture();

    Metadata metadata = new Metadata();
    metadata.setString('deliveryLocation', 'WaliedCheetos says Holllla');
    _addMarker(_hereMapController.camera.state.targetCoordinates, 1, metadata);

//initiate search engine
//
    try {
      _searchEngine = new SearchEngine();
    } on InstantiationException catch (instantiationException) {
      throw new Exception("Initialization of SearchEngine failed: " +
          instantiationException.error.toString());
    } catch (exception) {
      throw new Exception(exception.error.toString());
    }
    //_addAjmanPolygon();
  }

  void _setupPanGesture() {
    try {
      _hereMapController.gestures.panListener = PanListener.fromLambdas(
          lambda_onPan: (GestureState gestureState, Point2D origin,
              Point2D translation, double velocity) {
        // print(gestureState.toString());
        _mapMarker.coordinates =
            _hereMapController.camera.state.targetCoordinates;

        // print('Current marker location: ' +
        //     _mapMarker.coordinates.latitude.toString() +
        //     ',' +
        //     _mapMarker.coordinates.longitude.toString() +
        //     ',' +
        //     _mapMarker.coordinates.altitude.toString());

        if (gestureState == GestureState.end) {
          _reverseGeocode(_hereMapController.camera.state.targetCoordinates);
          _clearPolylines();

          _mapPolylineList.add(_prepareCurvedPolylines(
              GeoCoordinates(_appConfig.initialLAT, _appConfig.initialLNG),
              _hereMapController.camera.state.targetCoordinates));

          _hereMapController.mapScene.addMapPolyline(_mapPolylineList[0]);
        } else {}
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<Uint8List> _loadFileAsUint8List(String fileName) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load('assets/' + fileName);
    return Uint8List.view(fileData.buffer);
  }

  Future<void> _addMarker(
      GeoCoordinates geoCoordinates, int drawOrder, Metadata markerData) async {
    try {
      // Reuse existing MapImage for new map markers.
      if (_mapImageMarker == null) {
        Uint8List imagePixelData = await _loadFileAsUint8List('poi.png');
        _mapImageMarker = MapImage.withPixelDataAndImageFormat(
            imagePixelData, ImageFormat.png);
      }

      // By default, the anchor point is set to 0.5, 0.5 (= centered).
      // Here the bottom, middle position should point to the location.
      Anchor2D anchor2D = Anchor2D.withHorizontalAndVertical(0.5, 1);
      _mapMarker =
          MapMarker.withAnchor(geoCoordinates, _mapImageMarker, anchor2D);
      _mapMarker.drawOrder = drawOrder;
      _mapMarker.metadata = markerData;
      _hereMapController.mapScene.addMapMarker(_mapMarker);
      _mapMarkerList.add(_mapMarker);
    } catch (e) {
      log(e.toString());
    }
  }

  void _clearMapMarkers() {
    try {
      for (var mapMarker in _mapMarkerList) {
        _hereMapController.mapScene.removeMapMarker(mapMarker);
      }
      _mapMarkerList.clear();
    } catch (exception) {
      throw new Exception(exception.error.toString());
    }
  }

  void _clearPolylines() {
    try {
      for (var mapPolyline in _mapPolylineList) {
        _hereMapController.mapScene.removeMapPolyline(mapPolyline);
      }
      _mapPolylineList.clear();
    } catch (exception) {
      throw new Exception(exception.error.toString());
    }
  }

  void _addAjmanPolygon() {
    List<GeoCoordinates> geocoordiantesList = new List<GeoCoordinates>();
    List<String> geocoordinatesStringsList = _appConfig.polygonAjman.split(',');
    for (var i = 0; i < geocoordinatesStringsList.length; i++) {
      GeoCoordinates geoCoordinatesCurrent = new GeoCoordinates(
          double.parse(geocoordinatesStringsList[i].split(' ')[1]),
          double.parse(geocoordinatesStringsList[i].split(' ')[0]));

      geocoordiantesList.add(geoCoordinatesCurrent);
    }

    try {
      _geoPolygonAjman = new GeoPolygon(geocoordiantesList);
    } on InstantiationException catch (instantiationException) {
      throw new Exception("Initialization of Geopolygon failed: " +
          instantiationException.error.toString());
    } catch (exception) {
      throw new Exception(exception.error.toString());
    }
    _mapPolygonAjman =
        new MapPolygon(_geoPolygonAjman, Color.fromRGBO(255, 0, 0, 13));
    _hereMapController.mapScene.addMapPolygon(_mapPolygonAjman);
    print('Ajman polgon has been added to the map');
  }

  void _reverseGeocode(GeoCoordinates geoCoordinates) {
    if (_searchEngine != null) {
      _searchEngine.searchByCoordinates(
          geoCoordinates, new SearchOptions(LanguageCode.enUs, 1),
          (SearchError searchError, List<Place> placesList) {
        if (searchError == null && placesList.length > 0) {
          // _appConfig.addressPlaceHolder.value =
          //     new TextEditingValue(text: placesList[0].title);
          //print(placesList[0].title);
          // _appConfig.addressPlaceHolder.text = placesList[0].title;
          _textEditingController.text = placesList[0].title;
        } else {
          // print(_config.prefix + 'no address found');
          _appConfig.addressPlaceHolder.text =
              _appConfig.prefix + 'no address found';
        }
      });
    }
  }

  MapPolyline _prepareCurvedPolylines(
      GeoCoordinates point1, GeoCoordinates point2) {
    List<LatLng> pointsOnCurve = MapsCurvedLines.getPointsOnCurve(
        new LatLng(point1.latitude, point1.longitude),
        new LatLng(point2.latitude, point2.longitude));

    List<GeoCoordinates> coordinates = new List<GeoCoordinates>();
    for (var pointOnCurve in pointsOnCurve) {
      coordinates.add(
          new GeoCoordinates(pointOnCurve.latitude, pointOnCurve.longitude));
    }

    GeoPolyline geoPolyline;
    try {
      geoPolyline = new GeoPolyline(coordinates);
    } on InstantiationException catch (instantiationException) {
      throw new Exception("Initialization of geopolyline failed: " +
          instantiationException.error.toString());
    } catch (exception) {
      throw new Exception(exception.error.toString());
    }

    return new MapPolyline(geoPolyline, 20, Colors.red);
  }
}
