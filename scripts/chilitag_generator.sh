#!/bin/bash

# switch between creating just the individual tag mashes for gazebo, or the combined tag plates for printing
CREATE_MESHES=0

if [[ "${CREATE_MESHES}" == "1" ]]; then
    DPI=55
    OUTPUT_FORMAT="png"
    SVG_TEMPLATE="normal_margin.template.svg"
else
    DPI=300
    #OUTPUT_FORMAT="svg"
    OUTPUT_FORMAT="tiff"
    SVG_TEMPLATE="narrow_margin.template.svg"
fi

TEXT_COLOR="#707070"

ROWS=3
COLS=3
TAGS_PER_BOARD=$((ROWS * COLS))

OVERLAY_TAG_NAME="overlay tag name"
OVERLAY_TEXT_COLOR="#707070"
OVERLAY_SVG_TEMPLATE="tag_name_overlay.template.svg"
OVERLAY_DPI=118

# bash only supports integer calc, so multiply first and then divide...
OUTER_BORDER_WIDTH=$((DPI * 4 / 15))
OUTER_BORDER_COLOR=white

MAKE_A4_PDF=0

check_command() {
    COMMAND=$1
    if ! [[ -x "$(command -v ${COMMAND})" ]]; then
        command_not_found_handle ${COMMAND}
        exit 1
    fi
}

check_command convert

map_tag_id_to_tag_name() {
    python - $1 <<END
import sys
mapping = {
    '0': 'Dock 1',
    '9': 'Dock 2',
    '18': 'Dock 3',
    '27': 'Dock 4',
    '36': 'Dock 5',
    '45': 'Dock 6',
    '54': 'Bow 12:00',
    '63': 'Bow 10:30',
    '72': 'Bow 01:30',
    '81': 'Bow 09:00',
    '90': 'Bow 03:00',
    '99': 'Bow 07:30',
    '108': 'Bow 04:30',
    '117': 'POI 1',
    '126': 'POI 2',
    '135': 'POI 3',
    '144': 'POI 4',
    '153': 'POI 5',
    '162': 'POI 6',
    '171': 'POI 7',
    '180': 'POI 8',
    '189': 'POI 9',
}
print(mapping[sys.argv[1].split('_')[0]])
END
}

generate_chilitag() {
    local CHILITAG_ID=$1
    
    # create chilitag and trace it into an svg file
    chilitags-creator --stdout ${CHILITAG_ID} 20 | convert - ppm:- | potrace -s --output "${CHILITAG_ID}.svg"

    # extract actual chilitag graphic from svg
    CHILITAG_GRAPHIC=$(grep -Pzo "<g(.|\n)*</g>" "${CHILITAG_ID}.svg" | grep -Pzo "<path(.|\n)*/>")

    # insert chilitag graphic and id into SVG template
    CHILITAG_ID="${CHILITAG_ID}" CHILITAG_GRAPHIC="${CHILITAG_GRAPHIC}" TEXT_COLOR="${TEXT_COLOR}" envsubst < ${SVG_TEMPLATE} > "${CHILITAG_ID}.svg"

    if [[ "${OUTPUT_FORMAT}" != "svg" ]]; then
        # render svg to png (using inkscape for proper svg support)
        inkscape --export-dpi=${DPI} --export-png="${CHILITAG_ID}.png" "${CHILITAG_ID}.svg" >/dev/null

        if [[ "${OUTPUT_FORMAT}" != "png" ]]; then
            # convert png to OUTPUT_FORMAT format
            convert "${CHILITAG_ID}.png" "${CHILITAG_ID}.${OUTPUT_FORMAT}"
            rm "${CHILITAG_ID}.png"
        fi
        rm "${CHILITAG_ID}.svg"
    fi
}

generate_overlay() {
    local OVERLAY_TAG_NAME=$1

    # insert tag name into SVG template
    OVERLAY_TAG_NAME="${OVERLAY_TAG_NAME}" OVERLAY_TEXT_COLOR="${OVERLAY_TEXT_COLOR}" envsubst < ${OVERLAY_SVG_TEMPLATE} > "${OVERLAY_TAG_NAME}.svg"

    if [[ "${OUTPUT_FORMAT}" != "svg" ]]; then
        # render svg to png (using inkscape for proper svg support)
        inkscape --export-dpi=${OVERLAY_DPI} --export-png="${OVERLAY_TAG_NAME}.png" "${OVERLAY_TAG_NAME}.svg" >/dev/null

        if [[ "${OUTPUT_FORMAT}" != "png" ]]; then
            # convert png to OUTPUT_FORMAT format
            convert "${OVERLAY_TAG_NAME}.png" "${OVERLAY_TAG_NAME}.${OUTPUT_FORMAT}"
            rm "${OVERLAY_TAG_NAME}.png"
        fi
        rm "${OVERLAY_TAG_NAME}.svg"
    fi
}

make_row_name() {
    local start_id=$1
    local base_name=${start_id}
    for ((col = 1; col < COLS; col++)); do
        next_name=$((start_id + col))
        base_name="${base_name}_${next_name}"
    done
    echo ${base_name}
}

FIRST_ID=$1
if [[ -z ${FIRST_ID} ]]; then
    echo "usage $0 FIRST_ID [COUNT]"
    exit 1
fi

COUNT=$2
if [[ -z ${COUNT} ]]; then
    COUNT=1
fi
COUNT=$(( (COUNT + TAGS_PER_BOARD - 1) / TAGS_PER_BOARD * TAGS_PER_BOARD )) # round up to multiples of TAGS_PER_BOARD
LAST_ID=$((FIRST_ID + COUNT - 1))

# generate individual chilitags
for ((i = FIRST_ID; i <= LAST_ID; i++)); do
    generate_chilitag ${i}
done

if [[ "${CREATE_MESHES}" == "1" ]]; then
    echo "Finished creating individual tag meshes."
    exit
fi

# concatenate chilitags in a row
for ((i = FIRST_ID; i <= LAST_ID; i += COLS)); do
    base_name=${i}
    for ((col = 1; col < COLS; col++)); do
        next_name=$((i + col))
        convert "${base_name}.${OUTPUT_FORMAT}" "${next_name}.${OUTPUT_FORMAT}" +append "${base_name}_${next_name}.${OUTPUT_FORMAT}"
        rm "${base_name}.${OUTPUT_FORMAT}" "${next_name}.${OUTPUT_FORMAT}"
        base_name="${base_name}_${next_name}"
    done
done

# concatenate rows of chilitags
for ((i = FIRST_ID; i <= LAST_ID; i += TAGS_PER_BOARD)); do
    base_name=$(make_row_name ${i})
    for ((row = 1; row < ROWS; row++)); do
        next_name=$(make_row_name $((i + (row * COLS) )))
        # rotate only after last concat
        if ((row + 1 == ROWS)); then
            final_options="-rotate 180"
            if ((OUTER_BORDER_WIDTH > 0)); then
                final_options="${final_options} -bordercolor ${OUTER_BORDER_COLOR} -border ${OUTER_BORDER_WIDTH}"
            fi
        else
            final_options=""
        fi
        convert "${base_name}.${OUTPUT_FORMAT}" "${next_name}.${OUTPUT_FORMAT}" -append ${final_options} "${base_name}_${next_name}.${OUTPUT_FORMAT}"
        rm "${base_name}.${OUTPUT_FORMAT}" "${next_name}.${OUTPUT_FORMAT}"
        base_name="${base_name}_${next_name}"
    done
    if [[ "${OVERLAY_SVG_TEMPLATE}" != "" ]]; then
        tag_name=$(map_tag_id_to_tag_name "${base_name}")
        generate_overlay "${tag_name}"
        composite -gravity center "${tag_name}.${OUTPUT_FORMAT}" "${base_name}.${OUTPUT_FORMAT}" "${base_name}_${tag_name}.${OUTPUT_FORMAT}"
        rm "${tag_name}.${OUTPUT_FORMAT}"
        rm "${base_name}.${OUTPUT_FORMAT}"
        base_name="${base_name}_${tag_name}"
    fi
    if [[ "${MAKE_A4_PDF}" == "1" ]]; then
        # make PDF from bitmap
        sam2p -j:quiet "${base_name}.${OUTPUT_FORMAT}" "${base_name}.a4.pdf"
        # scale pdf to fit on A4 page
        sam2p_pdf_scale 595 842 "${base_name}.a4.pdf"
    fi
done

if [[ "${MAKE_A4_PDF}" == "1" ]]; then
    pdftk *.a4.pdf cat output all_tags.pdf
fi
