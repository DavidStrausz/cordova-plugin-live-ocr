# Cordova plugin for live OCR recognition using native [Tesseract](https://github.com/tesseract-ocr/tesseract) library - For Android and iOS

## Installation:
* `git clone https://github.com/DavidStrausz/cordova-plugin-live-ocr.git`
* `ionic plugin add cordova-plugin-live-ocr`
* `ionic platform remove <platform>`
* `ionic platform add <platform>`

## Integration in Ionic 2 project  

### Create a Native Wrapper:
* Create ionic native wrapper for plugin  
```typescript
import { Cordova, Plugin } from 'ionic-native';

@Plugin({
  plugin: 'cordova-plugin-live-ocr',
  pluginRef: 'LiveOcrPlugin',
  platforms: ['Android', 'iOS']
})
export class LiveOcrPlugin {
  @Cordova()
  static recognizeText(successCallback, errorCallback): Promise<any> { return; }

  @Cordova()
  static loadLanguage(language, successCallback, errorCallback): any { }
}
```

### Usage in project  
```typescript
import {LiveOcrPlugin} from 'path/to/native/wrapper/LiveOcrPlugin';
this.platform.ready().then(() => {
    //load language file for android (it is included for ios)
        LiveOcrPlugin.loadLanguage(
    'eng', 
    (success) => {
        //success callback
    },
    (error) => {
        //error callback
    });

    //start recognition process
    LiveOcrPlugin.recognizeText(
    (success) => {
        //success callback
    },
    (error) => {
        //error callback
    });
});
```

## Important Notes:
* when developing on different environments: remove platforms, remove `cordova-plugin-live-ocr`, install the plugin again, add platforms - otherwise the dependencies of `cordova-plugin-live-ocr` will be missing
* in general: if something unexpected happens - remove plugin, readd plugin, remove platform, readd platform

--------------------------------------------------------------------------- 

## iOS:

### DEV-requirements: 
* [Cocoapods](https://cocoapods.org) must be set up (master repository) 
  * This plugin creates a workspace project for iOS and checks for cocoapods in config.xml and plugin.xml's and installs them

### How to modify and build:
#### Optional when errors with bitcode occur:  
* Open workspace project in `platforms/ios`: 
* Project `Pods` -> Targets `TesseractOCRiOS` -> Build Settings -> Select `All` -> Search for `bitcode` -> Enable Bitcode `No`  
  
#### Modify and build:
* Following files, located in `cordova-plugin-live-ocr/src/ios` can be modified (header and implementation):
  * `AROverlayViewController`
  * `CaptureSessionManager`
  * `LiveOcrPlugin`
* Readd the plugin
* Build

--------------------------------------------------------------------------- 

## Android:

#### Basic changes can be done in these two files located in `cordova-plugin-live-ocr/src/android`:
* `LiveOcrPlugin.java`
* `OcrActivity.java`  

#### Changes which regard the camera view or the tesseract library can be done as follows:
##### Tess-two library:
* If you don't want to use precompiled and built tess-two.aar (which is strongly recommended):
  * Download [Android NDK](https://developer.android.com/ndk/downloads/index.html) and add to `Path`
  * Download or clone [tess-two project](https://github.com/rmtheis/tess-two) (it contains Tesseract library for Android) 
  * Compile tess-two using android ndk  
-change to `path/to/tess-two` in terminal  
-enter `ndk-build` (this takes a while, go drink a coffee)
  * Add the library to a android studio project
  * Build the project
  * New `.aar` file can be copied from `project-folder/tess-two/build/outputs/aar`

##### Camera view:
* Download or clone fork of [android-ocr](https://github.com/DavidStrausz/android-ocr.git)
* Open android project
  * Open Android Studio
  * Select import existing project
  * Select `platforms/android`
* Android Studio maybe complains about a few things (deprecated ndk use etc.)
* Delete the jnilibs included by the plugin in Android Studio: `android/jniLibs/*` (only needed for builds)
* Open `build.gradle (Module: android)`
  * Delete following line: `apply from: "cordova-plugin-live-ocr/<appid>-libs.gradle"`
* Include OCRTest (from previously cloned android-ocr fork) project as module in android project (select gradle project)
* Open `OcrActivity.java` (`android/java/at.ventocom.liveocr.OcrActivity`)
* Click into the red colored `CaptureActivity` and hit `alt + enter` to add a dependency on previously included OCRTest project
* When done modifying, build the project, copy `platforms/android/OCRTest/build/outputs/aar/OCRTest-release.aar` and replace the existing one in `cordova-plugin-live-ocr/lib` (don't forget to rename)

#### Finally:
* Remove the plugin, readd the plugin, remove android platform, readd platform  
* Rebuild

--------------------------------------------------------------------------- 

## TODO:
* Fix iOS crash: when tesseract is in the process of recognizing a text and user aborts scanning, the app may crash in some cases
* Test on different os versions (Android and iOS) - works on android 4.4+ and iOS 9, 10 - iOS 8.4 tested in emulator

### Possibly resolved by XCode8:
* Find a solution to disable bitcode automatically in Pods project (iOS) - possible solution: http://stackoverflow.com/questions/32640149/disable-bitcode-for-project-and-cocoapods-dependencies-with-xcode7, resolved by upgrading to xcode 8 non beta
* Use ionic build on macOS/OSX - fixed onmacos and xcode 8 by adding this line to cordova/lib build.js '-destination', 'platform=iOS Simulator,name=iPhone 6,OS=9.3', resolved by upgrading to xcode 8 non beta