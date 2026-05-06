Version
-------
 % which xcodebuild
/usr/bin/xcodebuild
 % ls -l /usr/bin/xcodebuild 
-rwxr-xr-x  16 root  wheel  135488 Apr  6 01:10 /usr/bin/xcodebuild
% xcodebuild -version
Xcode 26.2
Build version 17C52


Common Commands Used
--------------------
01. xcodebuild -list
02. xcodebuild -list -project MyApp.xcodeproj
03. xcodebuild -list -workspace MyApp.xcworkspace
04. open MyApp.xcodeproj
05. open MyApp.xcworkspace
06. xcodebuild clean
07. xcodebuild build
08. xcodebuild -scheme MyApp build
09. xcodebuild -scheme MyApp -destination "platform=iOS Simulator,name=iPhone 16" build
10. xcodebuild -scheme MyApp -destination "generic/platform=iOS" build
11. xcodebuild -scheme MyApp -configuration Debug -destination "generic/platform=iOS" build
12. xcodebuild -scheme MyApp -configuration Release -destination "generic/platform=iOS" build
13. xcodebuild test -scheme MyApp -destination "platform=iOS Simulator,name=iPhone 17"
14. xcodebuild test -scheme MyAppTests -destination "..."
15. xcodebuild test -scheme MyApp \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -destination "platform=iOS Simulator,name=iPhone SE" \
  -parallel-testing-enabled YES
16. xcodebuild archive -scheme MyApp \
  -destination "generic/platform=iOS" \
  -archivePath ./build/MyApp.xcarchive
17. xcodebuild -exportArchive \
  -archivePath ./build/MyApp.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ./exportOptions.plist
18. xcodebuild test -scheme MyApp -sdk -list -verbose


Workflow
--------
1. xcodebuild clean -scheme DinoGames
2. xcodebuild clean -scheme DinoGames -configuration Debug -target DinoGamesTests -destination "platform=IOS Simulator,name=iPhone 17"
2. xcodebuild clean build test -scheme DinoGames -destination "platform=iOS Simulator,name=iPhone 16"
3. xcodebuild clean archive -scheme MyApp \
  -destination "generic/platform=iOS" \
  -archivePath ./MyApp.xcarchive

Example
-------
% pwd
/Users/tim/Documents/workspace/swift/apps/dino-games/DinoGames
% xcodebuild -list
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -list

Information about project "DinoGames":
    Targets:
        DinoGames
        DinoGamesTests
        DinoGamesUITests

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        DinoGames
% xcodebuild clean -scheme DinoGames
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild clean -scheme DinoGames

2026-05-04 09:32:22.707 xcodebuild[24253:298792] [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, variant:Designed for [iPad,iPhone], id:00008132-000548DC0CE3801C, name:My Mac }
{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }
{ platform:iOS Simulator, arch:arm64, id:CF81CC7F-2708-4E70-B326-C43EB91D07AA, OS:26.2, name:iPad (A16) }
{ platform:iOS Simulator, arch:arm64, id:9BD06817-0276-4C7F-AB4E-9295372F2BE2, OS:26.2, name:iPad Air 11-inch (M3) }
{ platform:iOS Simulator, arch:arm64, id:6745A660-68A8-4E32-95AD-498358CF9A30, OS:26.2, name:iPad Air 13-inch (M3) }
{ platform:iOS Simulator, arch:arm64, id:7FE2ED06-CF51-4907-9B5C-2128309E1ECE, OS:26.2, name:iPad Pro 11-inch (M5) }
{ platform:iOS Simulator, arch:arm64, id:9E63F81F-87BE-48A7-B53A-090BE9969D38, OS:26.2, name:iPad Pro 13-inch (M5) }
{ platform:iOS Simulator, arch:arm64, id:39F3CE39-F0C1-4728-A13A-945F7962B32F, OS:26.2, name:iPad mini (A17 Pro) }
{ platform:iOS Simulator, arch:arm64, id:222A0C39-7186-4276-A65A-CBAFEEC07476, OS:26.2, name:iPhone 16e }
{ platform:iOS Simulator, arch:arm64, id:D761E1A5-286F-4B59-9A08-51EE352FFAB2, OS:26.2, name:iPhone 17 }
{ platform:iOS Simulator, arch:arm64, id:F6D01ABF-C9FC-4B58-B560-E801508AFEA6, OS:26.2, name:iPhone 17 Pro }
{ platform:iOS Simulator, arch:arm64, id:ED78951B-4DAA-4358-AF52-83F0352FA877, OS:26.2, name:iPhone 17 Pro Max }
{ platform:iOS Simulator, arch:arm64, id:D6E0E48C-856A-4E8D-8891-C85D992FDCF4, OS:26.2, name:iPhone Air }
{ platform:iOS, arch:arm64, id:00008110-000A150C1E23A01E, name:Timothy’s iPhone }
CreateBuildRequest

SendProjectDescription

CreateBuildOperation

** CLEAN SUCCEEDED **

% xcodebuild clean -scheme DinoGames -configuration Debug -target DinoGamesTests -destination "platform=IOS Simulator,name=iPhone 17"
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild clean -scheme DinoGames -configuration Debug -target DinoGamesTests -destination "platform=IOS Simulator,name=iPhone 17"

2026-05-04 09:34:33.333 xcodebuild[24348:300082] [MT] IDERunDestination: Supported platforms for the buildables in the current scheme is empty.
CreateBuildRequest

SendProjectDescription

CreateBuildOperation

** CLEAN SUCCEEDED **

