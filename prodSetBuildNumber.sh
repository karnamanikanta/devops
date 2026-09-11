Ver_String="$(defaults read $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/Finland-Info CFBundleShortVersionString)"
echo "Version_String=$Ver_String"
Build_Number_FromFile="$(defaults read $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/Finland-Info CFBundleVersion)"
Number="$BUILD_BUILDNUMBER"
Updated_Build_Number=$(($Build_Number_FromFile + $Number))
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/Finland-Info.plist" $Build_Number_FromFile
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Source/Finland QE1-Info.plist" $Build_Number_FromFile
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/SiriIntent/Info.plist" $Build_Number_FromFile
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/SiriIntentUI/Info.plist" $Build_Number_FromFile
ruby $SYSTEM_DEFAULTWORKINGDIRECTORY/setBuildNumber.rb "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/RichNotification/Info.plist" $Build_Number_FromFile
