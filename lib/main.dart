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

import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:WaliedCheetos_DTPOC/HERESetup.dart';
import 'package:WaliedCheetos_DTPOC/appConfig.dart';

void main() {
  SdkContext.init(IsolateOrigin.main);
  // Making sure that BuildContext has MaterialLocalizations widget in the widget tree,
  // which is part of MaterialApp.
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  // Use _context only within the scope of this widget.
  BuildContext _context;
  HERESetup _hereSetup;

  appConfig _appConfig = appConfig();
  BottomAppBar bottomNavigationBar;
  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _context = context;

    var scaffold = Scaffold(
      appBar: AppBar(
        title: Text(_appConfig.appTitle),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          HereMap(onMapCreated: _onMapCreated),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     button('Book a taxi',_anchoredMapMarkersButtonClicked),
          //     button('Say hi to Sarmad',_centeredMapMarkersButtonClicked),
          //     button('WaliedCheetos',_clearButtonClicked),
          //   ],
          // ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        // child: Text(_config.appTitle),
        child: TextField(
          // controller: _appConfig.addressPlaceHolder,
          controller: _textEditingController,
          decoration: InputDecoration(icon: Icon(Icons.location_history)),
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black),
        ),
        color: Colors.grey[300],
      ),
    );
    return MaterialApp(
      home: scaffold,
    );
  }

  // void _onMapCreated(HereMapController hereMapController) {
  //   hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
  //       (MapError error) {
  //     if (error == null) {
  //       _hereSetup =
  //           HERESetup(_context, hereMapController, _textEditingController);

  //       // HERESetup(_context,hereMapController);
  //     } else {
  //       print("Map scene not loaded. MapError: " + error.toString());
  //     }
  //   });
  // }

  void _onMapCreated(HereMapController hereMapController) {
    String mapScheme_Custom =
        '[your app path]/assets/mapScenes/omv/omv-traffic-traffic-normal-night.scene.json';

    hereMapController.mapScene.loadSceneFromConfigurationFile(mapScheme_Custom,
        (MapError error) {
      if (error == null) {
        _hereSetup =
            HERESetup(_context, hereMapController, _textEditingController);
        // HERESetup(_context,hereMapController);
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  // void _anchoredMapMarkersButtonClicked() {
  //   //_hereSetup.
  // }
  // void _centeredMapMarkersButtonClicked() {
  //   //_mapMarkerExample.showCenteredMapMarkers();
  // }

  // void _clearButtonClicked() {
  //   //_mapMarkerExample.clearMap();
  // }
/*
  void _anchoredMapMarkersButtonClicked() {
    _mapMarkerExample.showAnchoredMapMarkers();
  }

  void _centeredMapMarkersButtonClicked() {
    _mapMarkerExample.showCenteredMapMarkers();
  }

  void _clearButtonClicked() {
    _mapMarkerExample.clearMap();
  }
*/

  // A helper method to add a button on top of the HERE map.
  Align button(String buttonLabel, Function callbackFunction) {
    return Align(
      alignment: Alignment.topCenter,
      child: RaisedButton(
        color: Colors.lightBlueAccent,
        textColor: Colors.white,
        onPressed: () => callbackFunction(),
        child: Text(buttonLabel, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
