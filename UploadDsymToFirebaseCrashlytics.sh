# Write your commands here
find "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Archive/SubwayAppStore.xcarchive/dSYMs" -name "*.dSYM" | xargs -I \{\} $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Pods/FirebaseCrashlytics/upload-symbols -gsp $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Subway/Firebase/Prod/GoogleService-Info.plist -p ios \{\}
