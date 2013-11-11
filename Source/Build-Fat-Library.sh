xcodebuild -target OCMockLib -configuration Release -sdk iphonesimulator -arch i386 -arch x86_64
xcodebuild -target OCMockLib -configuration Release -sdk iphoneos -arch armv7 -arch armv7s -arch arm64

lipo -create -output ./libOCMock.a build/Release-iphoneos/libOCMock.a build/Release-iphonesimulator/libOCMock.a
