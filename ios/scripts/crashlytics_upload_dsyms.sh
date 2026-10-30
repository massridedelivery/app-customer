#!/bin/sh
# Xcode Run Script phase: upload this build's dSYMs to Firebase Crashlytics so
# iOS crash reports show readable stack traces. Release builds only.
#
# Uses the flavor's GoogleService-Info.plist (the same one "Copy Firebase
# config for flavor" puts in the app). Never fails the build: a failed upload
# only prints a warning.

case "$CONFIGURATION" in
  Release*) ;;
  *) exit 0 ;;
esac

case "$CONFIGURATION" in
  *-dev) FLAVOR_DIR=dev ;;
  *)     FLAVOR_DIR=prod ;;
esac

"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" --build-phase \
  -gsp "${SRCROOT}/config/${FLAVOR_DIR}/GoogleService-Info.plist" \
  || echo "warning: Crashlytics: dSYM upload failed"
exit 0
