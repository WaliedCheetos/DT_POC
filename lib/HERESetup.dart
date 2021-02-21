/*
 * Copyright (C) 2019-2020 HERE Europe B.V.
 *
 * Licensed under the Apache License,Version 2.0 (the "License")
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:WaliedCheetos_DTPOC/appConfig.dart';
import 'package:maps_curved_line/maps_curved_line.dart';

class HERESetup {
  BuildContext _context;
  appConfig _appConfig = appConfig();
  HereMapController _hereMapController;
  GeoPolygon _geoPolygonAjman;
  MapPolygon _mapPolygonAjman;
  MapImage _mapImageMarker;
  MapMarker _mapMarker;
  List<MapMarker3D> _mapMarker3DList = [];
  List<MapMarker> _mapMarkerList = [];
  List<MapPolyline> _mapPolylineList = [];
  TextEditingController _textEditingController;
  String _countryCode;
  String _city;

  HERESetup(BuildContext context, HereMapController hereMapController,
      TextEditingController textEditingController) {
    _textEditingController = textEditingController;
    _context = context;
    _hereMapController = hereMapController;

    _hereMapController.camera.lookAtPointWithDistance(
        GeoCoordinates(_appConfig.initialLAT, _appConfig.initialLNG),
        _appConfig.initialDistanceToEarthInMeters);

    _setupPanGesture();

    Metadata metadata = new Metadata();
    metadata.setString('deliveryLocation', 'WaliedCheetos says Holllla');
    _loadInitialTaxiLocations();
    _addMarker(_hereMapController.camera.state.targetCoordinates, 1, metadata);
    _addAjmanPolygon();
  }

  void _loadInitialTaxiLocations() {
    try {
      MapMarker3DModel mapMarker3DModel =
          MapMarker3DModel.withTextureFilePathAndColor(
              'assets/lexus_hs.obj',
              'assets/Lexus.jpg',
              Color.alphaBlend(Colors.yellow, Colors.black));
      MapMarker3D mapMarker3D;

      for (var taxiLocation in _appConfig.initialTaxiLocations.entries) {
        mapMarker3D = MapMarker3D(taxiLocation.key, mapMarker3DModel);
        mapMarker3D.bearing = taxiLocation.value;
        _hereMapController.mapScene.addMapMarker3d(mapMarker3D);
        _mapMarker3DList.add(mapMarker3D);
      }
    } catch (exception) {
      throw new Exception(exception);
    }
  }

  void _setupPanGesture() {
    try {
      _hereMapController.gestures.panListener = PanListener.fromLambdas(
          lambda_onPan: (GestureState gestureState, Point2D origin,
              Point2D translation, double velocity) {
        // print(gestureState.toString());
        _mapMarker.coordinates =
            _hereMapController.camera.state.targetCoordinates;

        if (gestureState == GestureState.end) {
          _reverseGeocode(_hereMapController.camera.state.targetCoordinates);
          _clearPolylines();

          // _mapPolylineList.add(_prepareCurvedPolylines(
          //     GeoCoordinates(_appConfig.initialLAT, _appConfig.initialLNG),
          //     _hereMapController.camera.state.targetCoordinates));

          // _hereMapController.mapScene.addMapPolyline(_mapPolylineList[0]);
        } else {}
      });
    } catch (exception) {
      throw new Exception(exception);
    }
  }

  void _reverseGeocode(GeoCoordinates geoCoordinates) async {
    try {
      String reverseGeocodingURL_at =
          'https://search.hereapi.com/v1/revgeocode?limit=1&lang=en-US&at=' +
              geoCoordinates.latitude.toString() +
              ',' +
              geoCoordinates.longitude.toString() +
              '&apikey=' +
              _appConfig.apikey;

      String reverseGeocodingURL_in =
          'https://search.hereapi.com/v1/revgeocode?limit=1&lang=en-US&in=circle:' +
              geoCoordinates.latitude.toString() +
              ',' +
              geoCoordinates.longitude.toString() +
              ';r=55' +
              '&apikey=' +
              _appConfig.apikey;

      print(reverseGeocodingURL_at);
      print(reverseGeocodingURL_in);

      http.Response response = await http.get(reverseGeocodingURL_in);

      if (response.statusCode == 200) {
        print(response.body);
        // If the server did return a 200 OK response,
        // then parse the JSON.
        final responseBody = jsonDecode(response.body);
        var items = responseBody['items'] as List;

        if (items.isNotEmpty) {
          _countryCode = items[0]['address']['countryCode'];
          _city = items[0]['address']['city'];

          print('${_city.toUpperCase()} , ${_countryCode.toUpperCase()}');

          _textEditingController.text = items[0]['title'];

          if (_countryCode.toUpperCase() == 'ARE' &&
              _city.toUpperCase() == 'AJMAN') {
            _mapPolylineList.add(_prepareCurvedPolylines(
                GeoCoordinates(_appConfig.initialLAT, _appConfig.initialLNG),
                geoCoordinates));

            _hereMapController.mapScene.addMapPolyline(_mapPolylineList[0]);
          } else {
            showDialog(
                context: _context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('WaliedCheetos says Hollla ...!!!'),
                    content: Text('We can NOT drop you off outside Ajman :-('),
                  );
                });
          }
        } else {
          _countryCode = '';
          _city = '';

          _textEditingController.text = _appConfig.prefix + 'no address found';
        }
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        _countryCode = '';
        _city = '';

        _textEditingController.text = _appConfig.prefix + 'no address found';
        throw Exception(
            'Failed to reverse geocode the provided coordinates: ${response.body}');
      }
    } catch (exception) {
      throw new Exception(exception);
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

      // By default,the anchor point is set to 0.5,0.5 (= centered).
      // Here the bottom,middle position should point to the location.
      Anchor2D anchor2D = Anchor2D.withHorizontalAndVertical(0.5, 1);
      _mapMarker =
          MapMarker.withAnchor(geoCoordinates, _mapImageMarker, anchor2D);
      _mapMarker.drawOrder = drawOrder;
      _mapMarker.metadata = markerData;
      _hereMapController.mapScene.addMapMarker(_mapMarker);
      _mapMarkerList.add(_mapMarker);
    } catch (exception) {
      throw new Exception(exception);
    }
  }

  void _clearMapMarkers() {
    try {
      for (var mapMarker in _mapMarkerList) {
        _hereMapController.mapScene.removeMapMarker(mapMarker);
      }
      _mapMarkerList.clear();
    } catch (exception) {
      throw new Exception(exception);
    }
  }

  void _clearPolylines() {
    try {
      for (var mapPolyline in _mapPolylineList) {
        _hereMapController.mapScene.removeMapPolyline(mapPolyline);
      }
      _mapPolylineList.clear();
    } catch (exception) {
      throw new Exception(exception);
    }
  }

  void _addAjmanPolygon() {
    List<GeoCoordinates> geocoordiantesList = new List<GeoCoordinates>();
    List<String> geocoordinatesStringsList = _appConfig.polygonAjman.split(',');
    for (var i = 0; i < geocoordinatesStringsList.length; i++) {
      GeoCoordinates geoCoordinatesCurrent = new GeoCoordinates(
          // double.parse(geocoordinatesStringsList[
          //         (geocoordinatesStringsList.length - (i + 1))]
          //     .split(' ')[1]),
          // double.parse(geocoordinatesStringsList[
          //         (geocoordinatesStringsList.length - (i + 1))]
          //     .split(' ')[0]));
          double.parse(geocoordinatesStringsList[i].split(' ')[1]),
          double.parse(geocoordinatesStringsList[i].split(' ')[0]));

      geocoordiantesList.add(geoCoordinatesCurrent);
    }

    geocoordinatesStringsList.clear();
    geocoordinatesStringsList = _appConfig.polygonAjman01.split(',');

    for (var i = 0; i < geocoordinatesStringsList.length; i++) {
      GeoCoordinates geoCoordinatesCurrent = new GeoCoordinates(
          // double.parse(geocoordinatesStringsList[
          //         (geocoordinatesStringsList.length - (i + 1))]
          //     .split(' ')[1]),
          // double.parse(geocoordinatesStringsList[
          //         (geocoordinatesStringsList.length - (i + 1))]
          //     .split(' ')[0]));
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
        new MapPolygon(_geoPolygonAjman, Color.fromRGBO(255, 0, 0, 0.3));

    _hereMapController.mapScene.addMapPolygon(_mapPolygonAjman);
    print('Ajman polgon has been added to the map');

// //new polygon
//     geocoordinatesStringsList.clear();

//     geocoordinatesStringsList = _appConfig.polygonAjman01.split(',');
//     for (var i = 0; i < geocoordinatesStringsList.length; i++) {
//       GeoCoordinates geoCoordinatesCurrent = new GeoCoordinates(
//           // double.parse(geocoordinatesStringsList[
//           //         (geocoordinatesStringsList.length - (i + 1))]
//           //     .split(' ')[1]),
//           // double.parse(geocoordinatesStringsList[
//           //         (geocoordinatesStringsList.length - (i + 1))]
//           //     .split(' ')[0]));
//           double.parse(geocoordinatesStringsList[i].split(' ')[1]),
//           double.parse(geocoordinatesStringsList[i].split(' ')[0]));

//       geocoordiantesList.add(geoCoordinatesCurrent);
//     }
//     GeoPolygon _geoPolygonAjman01;
//     MapPolygon _mapPolygonAjman01;
//     try {
//       _geoPolygonAjman01 = new GeoPolygon(geocoordiantesList);
//     } on InstantiationException catch (instantiationException) {
//       throw new Exception("Initialization of Geopolygon01 failed: " +
//           instantiationException.error.toString());
//     } catch (exception) {
//       throw new Exception(exception.error.toString());
//     }
//     _mapPolygonAjman01 =
//         new MapPolygon(_geoPolygonAjman01, Color.fromRGBO(255, 0, 0, 0.3));

//     _hereMapController.mapScene.addMapPolygon(_mapPolygonAjman01);
//     print('Ajman polgon01 has been added to the map');
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
      throw new Exception(exception);
    }

    return new MapPolyline(geoPolyline, 20, Colors.blueGrey);
  }
}
