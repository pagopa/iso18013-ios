#!/bin/bash

param="false"
# Check if the parameter is passed
if [ -z "$1" ]; then
    echo "run without parameters.. default don't rebuild if exists"
else
    param=$(echo "$1" | tr '[:upper:]' '[:lower:]')
fi

# If the parameter is false, check if IOWalletCIE.xcframework exists
if [ "$param" == "false" ]; then

  if [ -d ".archives/IOWalletProximity.xcframework" ]; then
    echo "IOWalletProximity.xcframework exists."
    exit 0
  else
    echo "no exists"
  fi
fi

echo "building xcframework"

# Remove the old /archives folder
rm -rf .archives

cd IOWalletProximity

# iOS Simulators
xcodebuild archive \
    -scheme IOWalletProximity \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "../.archives/IOWalletProximity-iOS-simulator.xcarchive" \
    -configuration Release \
    -sdk iphonesimulator 
   
# iOS Devices
xcodebuild archive \
    -scheme IOWalletProximity \
    -archivePath "../.archives/IOWalletProximity-iOS.xcarchive" \
    -destination "generic/platform=iOS" \
    -configuration Release \
    -sdk iphoneos 
    
# Build cbor.xcframework
xcodebuild -create-xcframework \
    -framework "../.archives/IOWalletProximity-iOS.xcarchive/Products/Library/Frameworks/IOWalletProximity.framework" \
    -framework "../.archives/IOWalletProximity-iOS-simulator.xcarchive/Products/Library/Frameworks/IOWalletProximity.framework" \
    -output "../.archives/IOWalletProximity.xcframework"