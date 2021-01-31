The DT-POC app shows how to:
- Pan the map and keep the marker in the center then retrieve the marker location (later we can add dynamic reverse geocoding to translate the coordinates into an address)
- Center the map into Ajman and add the respective city polygon
- Add route indication on the map


Build instructions:
-------------------

1) Set your HERE SDK credentials to
- `/android/app/src/main/AndroidManifest.xml`
- `/ios/Runner/Info.plist`

2) Unzip the HERE SDK plugin to the plugins folder inside this project. Name the folder 'here_sdk': /plugins/here_sdk

3) Start an emulator or simulator and execute `flutter run` from the app's directory - or run the app from within your IDE.

More information can be found in the _Get Started_ section of the _Developer's Guide_.
