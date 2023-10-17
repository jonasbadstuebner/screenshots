#!/bin/bash
set -u
PROGPATH=$(dirname "${BASH_SOURCE[0]}")

BLACK_COLOR="#000000dd"
WHITE_COLOR="#ffffffdd"

function calcInt() {
  calculation="${1:-}"
  [[ -z "$calculation" ]] && echo "cannot calculate on an empty calculation" && exit -1
  LC_NUMERIC="en_US.UTF-8" printf "%.0f" "$(echo "$calculation" | bc -l)"
}

function createBar() {
  out_path="${1:-}"
  width="${2:-}"
  bar_width="${3:-}"
  bar_height="${4:-}"
  bottom_padding="${5:-}"

  [[ -z "$out_path" ]] && echo "\$out_path is empty" && exit -1
  [[ ! -d "$out_path" ]] && echo "\$out_path is not a directory" && exit -1

  img_height=$(calcInt "$bar_height + $bottom_padding")

  size="${width}x${img_height}"
  edge_radius=$(calcInt "$bar_height / 2")

  left_x_pos=$(calcInt "( $width / 2 ) - ( $bar_width / 2 )")
  left_y_pos="0"

  right_x_pos=$(calcInt "$left_x_pos + $bar_width")
  right_y_pos=$(calcInt "$left_y_pos + $bar_height")

  convert -size "$size" xc:transparent -fill "$BLACK_COLOR" \
    -draw "roundrectangle $left_x_pos,$left_y_pos $right_x_pos,$right_y_pos $edge_radius,$edge_radius" \
    "$out_path/homeindicator_black.png"

  convert -size "$size" xc:transparent -fill "$WHITE_COLOR" \
    -draw "roundrectangle $left_x_pos,$left_y_pos $right_x_pos,$right_y_pos $edge_radius,$edge_radius" \
    "$out_path/homeindicator_white.png"
}

# list of folders that should contain home indicators; give the width of the frame
createBar "$PROGPATH/6.7inch-1290x2796" 1290 462 15 24
createBar "$PROGPATH/6.7inch-1284x2778" 1284 459 15 24
createBar "$PROGPATH/1242" 1242 444 15 24
createBar "$PROGPATH/1125" 1125 402 15 24
