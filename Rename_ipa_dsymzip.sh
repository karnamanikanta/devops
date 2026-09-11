#Rename ipa file according to build configuration
echo "Renaming ipa file"
mv $BUILD.ARTIFACTSTAGINGDIRECTORY/output/$SDK/$CONFIGURATION/'Subway Client Staging.ipa' $BUILD.ARTIFACTSTAGINGDIRECTORY/output/$SDK/$CONFIGURATION/Subway_Staging2_QE_$BUILD_BUILDID.ipa
#Rename zip file 
echo "Renaming zip file"
mv $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Archive/SubwayClientStaging.dSYM.zip $SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Archive/Subway_Staging2_QE_$BUILD_BUILDID.dSYM.zip
