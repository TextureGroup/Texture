#!/bin/bash
# echo ************* diagnostics
# echo available devices
# instruments -s devices
# echo available sdk
# xcodebuild -showsdks
# echo available Xcode
# ls -ld /Applications/Xcode*
# echo ************* diagnostics end

# run this on a 2x device until we've updated snapshot images to 3x
PLATFORM="${TEXTURE_BUILD_PLATFORM:-platform=iOS Simulator,OS=17.4,name=iPhone SE (3rd generation)}"
SDK="${TEXTURE_BUILD_SDK:-iphonesimulator17.4}"
DERIVED_DATA_PATH="~/ASDKDerivedData"

# It is pitch black.
set -e
function trap_handler {
	echo -e "\n\nOh no! You walked directly into the slavering fangs of a lurking grue!"
	echo "**** You have died ****"
	exit 255
}
trap trap_handler INT TERM EXIT

# Derived data handling
eval [ ! -d $DERIVED_DATA_PATH ] && eval mkdir $DERIVED_DATA_PATH
function clean_derived_data {
	eval find $DERIVED_DATA_PATH -mindepth 1 -delete
}

# Lint subspec
function lint_subspec {
	set -o pipefail && pod env && pod lib lint --verbose --allow-warnings --subspec="$1" --platforms=ios
}

function cleanup {
	# remove all Pods directories
	find . -name Pods -type d -exec rm -rf {} +
	find . -name Podfile.lock -type f -delete
}

MODE="$1"

cleanup

case "$MODE" in
tests | all)
	echo "Building & testing AsyncDisplayKit."
	pod install
	set -o pipefail && xcodebuild \
		-workspace AsyncDisplayKit.xcworkspace \
		-scheme AsyncDisplayKit \
		-sdk "$SDK" \
		-destination "$PLATFORM" \
		build-for-testing test
	success="1"
	;;

tests_listkit)
	echo "Building & testing AsyncDisplayKit+IGListKit."
	pod install --project-directory=SubspecWorkspaces/ASDKListKit
	set -o pipefail && xcodebuild \
		-workspace SubspecWorkspaces/ASDKListKit/ASDKListKit.xcworkspace \
		-scheme ASDKListKitTests \
		-sdk "$SDK" \
		-destination "$PLATFORM" \
		build-for-testing test
	success="1"
	;;

life-without-cocoapods | all)
	echo "Verifying that AsyncDisplayKit functions as a static library."

	set -o pipefail && xcodebuild \
		-workspace "smoke-tests/Life Without CocoaPods/Life Without CocoaPods.xcworkspace" \
		-scheme "Life Without CocoaPods" \
		-sdk "$SDK" \
		-destination "$PLATFORM" \
		build
	success="1"
	;;

framework | all)
	echo "Verifying that AsyncDisplayKit functions as a dynamic framework (for Swift/Carthage users)."

	set -o pipefail && xcodebuild \
		-project "smoke-tests/Framework/Sample.xcodeproj" \
		-scheme Sample \
		-sdk "$SDK" \
		-destination "$PLATFORM" \
		build
	success="1"
	;;

cocoapods-lint | all)
	echo "Verifying that podspec lints."

	set -o pipefail && pod env && pod lib lint
	success="1"
	;;

cocoapods-lint-default-subspecs)
	echo "Verifying that default subspecs lint."

	for subspec in 'Core' 'PINRemoteImage' 'Video' 'MapKit' 'AssetsLibrary' 'Photos'; do
		echo "Verifying that $subspec subspec lints."

		lint_subspec $subspec
	done
	success="1"
	;;

cocoapods-lint-other-subspecs)
	echo "Verifying that other subspecs lint."

	for subspec in 'IGListKit' 'Yoga' 'TextNode2'; do
		echo "Verifying that $subspec subspec lints."

		lint_subspec $subspec
	done
	success="1"
	;;

carthage | all)
	echo "Verifying carthage works."

	set -o pipefail && carthage update && carthage build --no-skip-current
	success="1"
	;;

*)
	echo "Unrecognized mode '$MODE'."
	;;
esac

if [ "$success" = "1" ]; then
	trap - EXIT
	exit 0
fi
