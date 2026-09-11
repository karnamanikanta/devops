echo "before CD"
echo $PWD
if [ -d "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Archive/Subway Client Staging.xcarchive/dSYMs" ] 
then
    echo "dir present"
    cd "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Archive/Subway Client Staging.xcarchive/dSYMs" && zip -r /Users/runner/work/1/s/Subway/Archive/SubwayClientStaging.dSYM.zip . -i *.dSYM
    #zip -r "$SYSTEM_DEFAULTWORKINGDIRECTORY/Subway/Archive/SubwayClientStaging.dSYM.zip" *.dSYM
    echo "After CD"
    echo $PWD
else
    echo "dir not present"
fi
