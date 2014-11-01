# This makefile is mainly intended for use on the CI server (Travis). It
# requires xcpretty to be installed.

# If you are trying to build a release locally consider using the build.rb
# script in the Tools directory instead.


BUILD_DIR = OBJROOT="$(CURDIR)/build" SYMROOT="$(CURDIR)/build"
SHELL = /bin/bash -e -o pipefail
IPHONE = -scheme OCMockLib -sdk iphonesimulator -destination 'name=iPhone 4S' $(BUILD_DIR)
MACOSX = -scheme OCMock -sdk macosx $(BUILD_DIR)
XCODEBUILD = xcodebuild -project "$(CURDIR)/Source/OCMock.xcodeproj"

ci: clean test

clean:
	$(XCODEBUILD) clean
	rm -rf "$(CURDIR)/build"

test: test-iphone test-macosx

test-iphone:
	@echo "Running iPhone tests..."
	$(XCODEBUILD) $(IPHONE) test | xcpretty -c

test-macosx:
	@echo "Running OS X tests..."
	$(XCODEBUILD) $(MACOSX) test | xcpretty -c
