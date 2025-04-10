<<<<<<< HEAD
# Object_Detection_android
=======
# Flutter Realtime Object Detection and Navigation

A mobile app that:
- Detects common objects in realtime via rear camera smartphone
- Find object:
  - Extract queried object (target) from voice command input
  - Confirm target by Google/Siri voice
  - Vibrates if the target is found, which helpsthe  target navigate
  - Vibration amplitude and duration proportional to the relative distance to object
- What's around
  - Divide screen into three regions (left, right, middle)
  - Group objects into corresponding regions
  - Response "object_count+object_label+corresponding region" as speech (google/siri voice)

## Developer: 
<span style="font-size: 18px;">[SauronVan](https://github.com/SauronVan)</span>

## Credit
Implemented from https://github.com/ultralytics/yolo-flutter-app by https://github.com/asabri97

## Note
- JDK 17
- Graddle > 8.3
- Android SDK ~35

## Demo

![Demo](assets/att.PYL35xMcuTcMFX8VVAqb_P316Iuu5UKOPFOE1RnkqMc.jpg"Demo")


## Getting Started

This project is a starting point for a Flutter application.
