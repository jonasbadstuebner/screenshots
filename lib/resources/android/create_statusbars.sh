#!/bin/bash
set -euo pipefail

PROGPATH=$(dirname "${BASH_SOURCE[0]}")

BLACK_COLOR="#000000ee"
BLACK_GREY="#00000060"
WHITE_COLOR="#ffffffff"
WHITE_GREY="#ffffff60"

TIME="9:41"
BATTERY_PERCENTAGE="75"
SIGNAL_PERCENTAGE="67"

SIGNAL_BLACK_PATH="$PROGPATH/assets/signal_black.png"
SIGNAL_WHITE_PATH="$PROGPATH/assets/signal_white.png"

WIFI_BLACK_PATH="$PROGPATH/assets/wifi_black.png"
WIFI_WHITE_PATH="$PROGPATH/assets/wifi_white.png"

BATTERY_BLACK_PATH="$PROGPATH/assets/battery_black.png"
BATTERY_WHITE_PATH="$PROGPATH/assets/battery_white.png"

function calcFloat() {
  calculation="${1:-}"
  precision="${2:-0}"
  [[ -z "$calculation" ]] && echo "cannot calculate on an empty calculation" && exit -1
  LC_NUMERIC="en_US.UTF-8" printf "%.${precision}f" "$(echo "$calculation" | bc -l)"
}

function calcInt() {
  calculation="${1:-}"
  calcFloat "$calculation"
}

function prepareAssets() {
  signal_img_width="440"
  signal_img_height="440"

  signal_edge_width="50"
  signal_margin="5"

  signal_1_point_x="$signal_margin"
  signal_1_point_y=$(calcInt "$signal_img_height - $signal_margin")

  signal_2_point_x=$(calcInt "$signal_img_width - $signal_margin")
  signal_2_point_y=$(calcInt "$signal_img_height - $signal_margin")

  signal_3_point_x=$(calcInt "$signal_img_width - $signal_margin")
  signal_3_point_y="$signal_margin"

  signal_1_inner_point_x=$(calcInt "$signal_img_width - $signal_edge_width")
  signal_1_inner_point_y=$(calcInt "$signal_edge_width * 2.1 + $signal_margin")

  signal_2_inner_point_x=$(calcInt "$signal_img_width - $signal_edge_width")
  signal_2_inner_point_y=$(calcInt "$signal_img_height - $signal_edge_width")

  signal_free_width=$(calcInt "( $signal_2_inner_point_y - $signal_1_inner_point_y ) * (100 - $SIGNAL_PERCENTAGE) / 100")
  signal_free_height=$(calcInt "$signal_free_width * $signal_img_height / $signal_img_width")

  signal_3_inner_point_x=$(calcInt "$signal_1_inner_point_x - $signal_free_width")
  signal_3_inner_point_y=$(calcInt "$signal_img_height - $signal_edge_width")

  signal_4_inner_point_x="$signal_3_inner_point_x"
  signal_4_inner_point_y=$(calcInt "$signal_1_inner_point_y + $signal_free_height")

  # create a signal png
  convert -size "${signal_img_width}x${signal_img_height}" xc:transparent \
    -fill "$BLACK_COLOR" \
    -strokewidth "1" \
    -stroke "$BLACK_COLOR" \
    -draw "path 'M $signal_1_point_x,$signal_1_point_y  L $signal_2_point_x,$signal_2_point_y  L $signal_3_point_x,$signal_3_point_y L $signal_1_inner_point_x,$signal_1_inner_point_y L $signal_2_inner_point_x,$signal_2_inner_point_y L $signal_3_inner_point_x,$signal_3_inner_point_y L $signal_4_inner_point_x,$signal_4_inner_point_y L $signal_1_inner_point_x,$signal_1_inner_point_y L $signal_3_point_x,$signal_3_point_y Z'" \
    "$SIGNAL_BLACK_PATH"

  convert -size "${signal_img_width}x${signal_img_height}" xc:transparent \
    -fill "$WHITE_COLOR" \
    -strokewidth "1" \
    -stroke "$WHITE_COLOR" \
    -draw "path 'M $signal_1_point_x,$signal_1_point_y  L $signal_2_point_x,$signal_2_point_y  L $signal_3_point_x,$signal_3_point_y L $signal_1_inner_point_x,$signal_1_inner_point_y L $signal_2_inner_point_x,$signal_2_inner_point_y L $signal_3_inner_point_x,$signal_3_inner_point_y L $signal_4_inner_point_x,$signal_4_inner_point_y L $signal_1_inner_point_x,$signal_1_inner_point_y L $signal_3_point_x,$signal_3_point_y Z'" \
    "$SIGNAL_WHITE_PATH"

  wifi_img_width="530"
  wifi_img_height="430"

  wifi_strokewidth="530"
  wifi_inner_offset="150"

  wifi_angle="80"

  wifi_angle_left=$(calcInt "270 - $wifi_angle / 2")
  wifi_angle_right=$(calcInt "$wifi_angle_left + $wifi_angle")

  convert -size "${wifi_img_width}x${wifi_img_height}" xc:transparent \
    -fill "transparent" \
    -stroke "$BLACK_COLOR" \
    -strokewidth "$wifi_strokewidth" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_inner_offset,$wifi_inner_offset $wifi_angle_left,$wifi_angle_right" \
    "$WIFI_BLACK_PATH"

  convert -size "${wifi_img_width}x${wifi_img_height}" xc:transparent \
    -fill "transparent" \
    -stroke "$WHITE_COLOR" \
    -strokewidth "$wifi_strokewidth" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_inner_offset,$wifi_inner_offset $wifi_angle_left,$wifi_angle_right" \
    "$WIFI_WHITE_PATH"

  battery_img_width="270"
  battery_img_height="460"

  battery_pole_width="110"
  battery_pole_height="50"
  battery_margin="5"

  battery_body_border_radius="30"

  battery_body_1_x="0"
  battery_body_1_y="$battery_pole_height"

  battery_body_2_x=$(calcInt "$battery_img_width")
  battery_body_2_y=$(calcInt "$battery_img_height - $battery_margin")

  battery_pole_1_x=$(calcInt "$battery_img_width / 2 - $battery_pole_width / 2")
  battery_pole_1_y="$battery_margin"

  battery_pole_2_x=$(calcInt "$battery_pole_1_x + $battery_pole_width")
  battery_pole_2_y="$battery_pole_height"

  convert -size "${battery_img_width}x${battery_img_height}" xc:transparent \
    -fill "$BLACK_COLOR" \
    -draw "roundrectangle $battery_body_1_x,$battery_body_1_y $battery_body_2_x,$battery_body_2_y $battery_body_border_radius,$battery_body_border_radius" \
    -draw "rectangle $battery_pole_1_x,$battery_pole_1_y $battery_pole_2_x,$battery_pole_2_y" \
    "$BATTERY_BLACK_PATH"

  convert -size "${battery_img_width}x${battery_img_height}" xc:transparent \
    -fill "$WHITE_COLOR" \
    -draw "roundrectangle $battery_body_1_x,$battery_body_1_y $battery_body_2_x,$battery_body_2_y $battery_body_border_radius,$battery_body_border_radius" \
    -draw "rectangle $battery_pole_1_x,$battery_pole_1_y $battery_pole_2_x,$battery_pole_2_y" \
    "$BATTERY_WHITE_PATH"

  SIGNAL_ASPECT_RATIO=$(calcFloat "$(identify -ping -format '%[width]/%[height]\n' "$SIGNAL_BLACK_PATH")" "4")
  WIFI_ASPECT_RATIO=$(calcFloat "$(identify -ping -format '%[width]/%[height]\n' "$WIFI_BLACK_PATH")" "4")
  BATTERY_ASPECT_RATIO=$(calcFloat "$(identify -ping -format '%[width]/%[height]\n' "$BATTERY_BLACK_PATH")" "4")
}

function createBar() {
  out_path="${1:-}"
  width="${2:-}"
  bar_height="${3:-}"
  icons_height="${4:-}"
  icons_padding="${5:-}"

  [[ -z "$out_path" ]] && echo "\$out_path is empty" && exit -1
  [[ ! -d "$out_path" ]] && echo "\$out_path '$out_path' is not a directory" && exit -1

  size="${width}x${bar_height}"

  font_size="$(calcInt "$icons_height * 1.4")"

  general_x_offset=$(calcInt "$width / 4")

  time_x_pos=$(calcInt "$general_x_offset * -1")
  time_y_pos=$(calcInt "- ( $font_size / 4)")

  black_out_img="$out_path/statusbar_black.png"
  white_out_img="$out_path/statusbar_white.png"

  signal_width=$(calcInt "$icons_height * $SIGNAL_ASPECT_RATIO")
  wifi_width=$(calcInt "$icons_height * $WIFI_ASPECT_RATIO")
  battery_width=$(calcInt "$icons_height * $BATTERY_ASPECT_RATIO")

  # middle of the icons
  icon_side_total_width=$(calcInt "$signal_width + $wifi_width + $battery_width + (2 * $icons_padding)")
  icons_start_x_offset=$(calcInt "$general_x_offset - ($icon_side_total_width / 2)")

  signal_offset="+$(calcInt "$icons_start_x_offset + ($signal_width / 2)")+0"
  wifi_offset="+$(calcInt "$icons_start_x_offset + $signal_width + ($wifi_width / 2) + $icons_padding")+0"
  battery_offset="+$(calcInt "$icons_start_x_offset + $signal_width + $wifi_width + ($battery_width / 2) + (2 * $icons_padding)")+0"

  # Create background with system time
  convert -size "$size" xc:transparent -font SF-UI-Display-Medium -pointsize "$font_size" \
    -background transparent -fill "$BLACK_COLOR" \
    -page "+0+0" -draw "gravity South fill "$BLACK_COLOR" text $time_x_pos,$time_y_pos '$TIME'" \
    -flatten "$black_out_img"

  convert -size "$size" xc:transparent -font SF-UI-Display-Medium -pointsize "$font_size" \
    -background transparent -fill "$WHITE_COLOR" \
    -page "+0+0" -draw "gravity South fill "$WHITE_COLOR" text $time_x_pos,$time_y_pos '$TIME'" \
    -flatten "$white_out_img"

  ## Overlay backgrounds with icons

  convert "$black_out_img" \
    \( "$SIGNAL_BLACK_PATH" -geometry "$signal_offset" -resize "x${icons_height}" \) -gravity south -geometry "$signal_offset" -composite \
    \( "$WIFI_BLACK_PATH" -geometry "$wifi_offset" -resize "x${icons_height}" \) -gravity south -geometry "$wifi_offset" -composite \
    \( "$BATTERY_BLACK_PATH" -geometry "$battery_offset" -resize "x${icons_height}" \) -gravity south -geometry "$battery_offset" -composite \
    -background none -flatten "$black_out_img"

  convert "$white_out_img" \
    \( "$SIGNAL_WHITE_PATH" -geometry "$signal_offset" -resize "x${icons_height}" \) -gravity south -geometry "$signal_offset" -composite \
    \( "$WIFI_WHITE_PATH" -geometry "$wifi_offset" -resize "x${icons_height}" \) -gravity south -geometry "$wifi_offset" -composite \
    \( "$BATTERY_WHITE_PATH" -geometry "$battery_offset" -resize "x${icons_height}" \) -gravity south -geometry "$battery_offset" -composite \
    -background none -flatten "$white_out_img"
}

prepareAssets

# list of folders that should contain status bars;
# give:
#  1) the output folder,
#  2) the width of the frame,
#  3) the height of the frame,
#  4) height of the signal icon
#     - (easiest to measure, the others get calculated from that),
#  5) padding between the signal and battery icon
#     - (easiest to measure, the others get calculated from that).
# I got the information from closely inspecting
# screenshots taken on simulators.
# createBar "$PROGPATH/6.7inch-1290x2796" 1290 92 484 38 24
createBar "$PROGPATH/1440" 1440 168 44 25
createBar "$PROGPATH/1080" 1080 168 44 25
