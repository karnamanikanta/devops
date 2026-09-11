Ver_String="$(defaults read $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/NA-Info CFBundleShortVersionString)"
echo "Version_String=$Ver_String"
Build_Number_FromFile="$(defaults read $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/NA-Info CFBundleVersion)"
Number="$BUILD_BUILDNUMBER"
Updated_Build_Number=$(($Build_Number_FromFile + $Number))
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/NA-Info.plist" $Updated_Build_Number
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/NA QE1-Info.plist" $Updated_Build_Number
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/SiriIntent/Info.plist" $Updated_Build_Number
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/SiriIntentUI/Info.plist" $Updated_Build_Number
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/RichNotification/Info.plist" $Updated_Build_Number
