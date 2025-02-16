#!/bin/bash
# Remove the old /archives folder
rm -rf archives

cd IOWalletProximity

# iOS Simulators
xcodebuild archive \
    -scheme IOWalletProximity \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "../archives/IOWalletProximity-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator \
    ONLY_ACTIVE_ARCH=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# iOS Devices
xcodebuild archive \
    -scheme IOWalletProximity \
    -archivePath "../archives/IOWalletProximity-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos \
    ONLY_ACTIVE_ARCH=NO \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
# Build cbor.xcframework
xcodebuild -create-xcframework \
    -framework "../archives/IOWalletProximity-iOS.xcarchive/Products/Library/Frameworks/IOWalletProximity.framework" \
    -framework "../archives/IOWalletProximity-iOS-simulator.xcarchive/Products/Library/Frameworks/IOWalletProximity.framework" \
    -output "../archives/IOWalletProximity.xcframework"