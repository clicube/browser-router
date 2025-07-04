#!/bin/bash -e

rm -rf .build/
rm -rf BrowserRouter.app
mkdir -p .build
mkdir -p .build/BrowserRouter.app/Contents/MacOS
cp Info.plist .build/BrowserRouter.app/Contents/

swift package update
swift build -c release


cp .build/release/SwiftBrowserRouter .build/BrowserRouter.app/Contents/MacOS/BrowserRouter
# codesign -s - --force --deep .build/BrowserRouter.app

mv .build/BrowserRouter.app BrowserRouter.app
