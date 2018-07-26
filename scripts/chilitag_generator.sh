#!/bin/bash

DPI=300
OUTPUT_FORMAT="tiff"
TEXT_COLOR="#505050"

generate_chilitag() {
    CHILITAG_ID=$1
    
    # create chilitag and trace it into an svg file
    PATH=$PATH:$ROS_WORKSPACE/../devel/bin chilitags-creator --stdout ${CHILITAG_ID} 20 | convert - ppm:- | potrace -s --output "${CHILITAG_ID}.svg"

    # extract actual chilitag graphic from svg
    CHILITAG_GRAPHIC=$(grep -Pzo "<g(.|\n)*</g>" "${CHILITAG_ID}.svg") 

    # insert chilitag graphic and id into template svg
    CHILITAG_ID="${CHILITAG_ID}" CHILITAG_GRAPHIC="${CHILITAG_GRAPHIC}" TEXT_COLOR="${TEXT_COLOR}" envsubst < template.svg > "${CHILITAG_ID}.svg"

    # render svg to png (using inkscape for proper svg support)
    inkscape --export-dpi=${DPI} --export-png="${CHILITAG_ID}.png" "${CHILITAG_ID}.svg" >/dev/null

    if [ "${OUTPUT_FORMAT}" != "png" ]; then
        # convert png to OUTPUT_FORMAT format
        convert "${CHILITAG_ID}.png" "${CHILITAG_ID}.${OUTPUT_FORMAT}"
        rm "${CHILITAG_ID}.png"
    fi
    rm "${CHILITAG_ID}.svg"
}

FIRST_ID=$1
if [ -z $FIRST_ID ]; then
    echo "usage $0 FIRST_ID [COUNT]"
    exit 1
fi

COUNT=$2
if [ -z $COUNT ]; then
    COUNT=1
fi
COUNT=$(((COUNT+3)/4*4)) # round up to multiples of 4
LAST_ID=$((FIRST_ID+COUNT-1))

# generate individual chilitags
for ((i=$FIRST_ID;i<=$LAST_ID;i++)); do
    generate_chilitag $i
done

# concatenate two chilitags horizontally
for ((i=$FIRST_ID;i<=$LAST_ID;i+=2)); do
    j=$((i+1))
    convert "${i}.${OUTPUT_FORMAT}" "${j}.${OUTPUT_FORMAT}" +append "${i}_${j}.${OUTPUT_FORMAT}"
    rm "${i}.${OUTPUT_FORMAT}" "${j}.${OUTPUT_FORMAT}"
done

# concatenate two double-chilitags vertically
for ((i=$FIRST_ID;i<=$LAST_ID;i+=4)); do
    j=$((i+1))
    k=$((i+2))
    l=$((i+3))
    convert "${i}_${j}.${OUTPUT_FORMAT}" "${k}_${l}.${OUTPUT_FORMAT}" -append "${i}_${j}_${k}_${l}.${OUTPUT_FORMAT}"
    rm "${i}_${j}.${OUTPUT_FORMAT}" "${k}_${l}.${OUTPUT_FORMAT}"
done
