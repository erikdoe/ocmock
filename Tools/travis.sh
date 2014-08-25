#!/bin/bash    

# adapted from: https://gist.github.com/henrikhodne/73151fccea7af3201f63

 
SCRIPT_DIR=$(dirname "$0")

run_xcodebuild ()
{
	local scheme=$1
	local sdk=$2
	local destination=$3
	echo "*** Building and testing $scheme..."
	xcodebuild -scheme "$scheme" -sdk "$sdk" -destination="$destination" -configuration Debug test OBJROOT="$PWD/build" SYMROOT="$PWD/build"

	local status=$?
 
	return $status
}
 
build_scheme ()
{
	run_xcodebuild "$1" "$2" "$3" 2>&1 | awk -f "$SCRIPT_DIR/xcodebuild.awk"
 
	local awkstatus=$?
	local xcstatus=${PIPESTATUS[0]}
 
	if [ "$xcstatus" -eq "65" ]
	then
		echo "*** Error building scheme $scheme"
	elif [ "$awkstatus" -eq "1" ]
	then
		return $awkstatus
	fi
 
	return $xcstatus
}
 
build_scheme OCMock macosx || exit $?
# Specified the destination for OCMockLib scheme in order to fix the `Error spawning child process: No such file or directory` error.
build_scheme OCMockLib iphonesimulator "platform=iOS Simulator,name=iPhone Retina (4-inch),OS=7.0" || exit $?
