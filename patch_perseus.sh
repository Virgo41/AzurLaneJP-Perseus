#!/bin/bash

# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

if [ ! -f "com.YoStarJP.AzurLane" ]; then
    echo "Get Azur Lane apk"
    wget https://dl-pc-sz-cf.pds.quark.cn/4qd6MFll/5632021470/6530f4ddfa46bf254bce4d3a9751765d7ce0bda4/6530f4dd3db63b21eaca4d3b88db9fa5ce7c4070?Expires=1697728901&OSSAccessKeyId=LTAIyYfxTqY7YZsg&Signature=zMHHLZG7gTzLJb37H4B94oLXbVs%3D&x-oss-traffic-limit=503316480&response-content-disposition=attachment%3B%20filename%3Dbase.apk&callback-var=eyJ4OmF1IjoiLSIsIng6dWQiOiIxNi0wLTYtMC04LU4tNC1OLTEtMTYtMC1OIiwieDpzcCI6IjE5OSIsIng6dG9rZW4iOiI0LTRjYmQ0ZGRkYTlkMGU2ZTczNzViMTY4MzAxZWU5MzA5LTgtMS01MDAtNzYyMTVlNzIwNTdkNDM3ZTg1NmY2ZWM1Y2Q0MTFkYTYtMC0wLTAtMC1hNDY0MDY2MmU2YzRmMjA1ODI5MDI5Nzc3ZWMzZDRlZiIsIng6dHRsIjoiMjE2MDAifQ%3D%3D&callback=eyJjYWxsYmFja0JvZHlUeXBlIjoiYXBwbGljYXRpb24vanNvbiIsImNhbGxiYWNrU3RhZ2UiOiJiZWZvcmUtZXhlY3V0ZSIsImNhbGxiYWNrRmFpbHVyZUFjdGlvbiI6Imlnbm9yZSIsImNhbGxiYWNrVXJsIjoiaHR0cHM6Ly9jbG91ZC1hdXRoLmRyaXZlLnF1YXJrLmNuL291dGVyL29zcy9jaGVja3BsYXkiLCJjYWxsYmFja0JvZHkiOiJ7XCJob3N0XCI6JHtodHRwSGVhZGVyLmhvc3R9LFwic2l6ZVwiOiR7c2l6ZX0sXCJyYW5nZVwiOiR7aHR0cEhlYWRlci5yYW5nZX0sXCJyZWZlcmVyXCI6JHtodHRwSGVhZGVyLnJlZmVyZXJ9LFwiY29va2llXCI6JHtodHRwSGVhZGVyLmNvb2tpZX0sXCJtZXRob2RcIjoke2h0dHBIZWFkZXIubWV0aG9kfSxcImlwXCI6JHtjbGllbnRJcH0sXCJwb3J0XCI6JHtjbGllbnRQb3J0fSxcIm9iamVjdFwiOiR7b2JqZWN0fSxcInNwXCI6JHt4OnNwfSxcInVkXCI6JHt4OnVkfSxcInRva2VuXCI6JHt4OnRva2VufSxcImF1XCI6JHt4OmF1fSxcInR0bFwiOiR7eDp0dGx9LFwiZHRfc3BcIjoke3g6ZHRfc3B9LFwiY2xpZW50X3Rva2VuXCI6JHtxdWVyeVN0cmluZy5jbGllbnRfdG9rZW59fSJ9&ud=16-0-6-0-8-N-4-N-1-16-0-N -O com.YoStarJP.AzurLane.apk -q
    echo "apk downloaded !"
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.YoStarJP.AzurLane.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.YoStarJP.AzurLane/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.YoStarJP.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.YoStarJP.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.YoStarJP.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.YoStarJP.AzurLane -o build/com.YoStarJP.AzurLane.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.YoStarJP.AzurLane -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
