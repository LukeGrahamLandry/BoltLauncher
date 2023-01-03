# BoltLauncher Dart Library

## Structure

- install
    - download all files required to run minecraft with a given mod loader
- launch.dart
    - start the game
- auth
    - login with microsoft account
- api_models
    - data structures fetched from metadata urls 
- data
    - options.dart
        - global settings that effect all instances
    - cache.dart
        - request remote data which is cached whenever possible
    - locations.dart
        - paths to import files/folders
    - profile.dart
        - settings that affect a single instance
