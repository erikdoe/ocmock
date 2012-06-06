
default:
	xcodebuild -target "OCMockLib" -configuration Release -sdk iphoneos
	xcodebuild -target "OCMockLib" -configuration Release -sdk iphonesimulator
	sh Scripts/iOSFramework.sh

# If you need to clean a specific target/configuration: $(COMMAND) -target $(TARGET) -configuration DebugOrRelease -sdk $(SDK) clean
clean:
	-rm -rf build/*
