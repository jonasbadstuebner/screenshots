#!/bin/bash
set -euo pipefail

PROGPATH=$(dirname "${BASH_SOURCE[0]}")

BLACK_COLOR="#000000ee"
BLACK_GREY="#00000060"
WHITE_COLOR="#ffffffff"
WHITE_GREY="#ffffff60"

TIME="9:41"
BATTERY_PERCENTAGE="75"

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
  signal_img_width="520"
  signal_img_height="320"

  signal_bar_width="90"
  signal_bar_spacing="50"

  signal_border_radius="40"

  signal_1_height="110"
  signal_2_height="160"
  signal_3_height="240"
  signal_4_height="320"

  signal_1_x=$(calcInt "$signal_img_height - $signal_1_height")
  signal_1_y_1="0"
  signal_1_y_2=$(calcInt "$signal_1_y_1 + $signal_bar_width")
  signal_1_cmd="roundrectangle $signal_1_y_1,$signal_1_x $signal_1_y_2,$signal_img_height $signal_border_radius,$signal_border_radius"

  signal_2_x=$(calcInt "$signal_img_height - $signal_2_height")
  signal_2_y_1=$(calcInt "$signal_1_y_2 + $signal_bar_spacing")
  signal_2_y_2=$(calcInt "$signal_2_y_1 + $signal_bar_width")
  signal_2_cmd="roundrectangle $signal_2_y_1,$signal_2_x $signal_2_y_2,$signal_img_height $signal_border_radius,$signal_border_radius"

  signal_3_x=$(calcInt "$signal_img_height - $signal_3_height")
  signal_3_y_1=$(calcInt "$signal_2_y_2 + $signal_bar_spacing")
  signal_3_y_2=$(calcInt "$signal_3_y_1 + $signal_bar_width")
  signal_3_cmd="roundrectangle $signal_3_y_1,$signal_3_x $signal_3_y_2,$signal_img_height $signal_border_radius,$signal_border_radius"

  signal_4_x=$(calcInt "$signal_img_height - $signal_4_height")
  signal_4_y_1=$(calcInt "$signal_3_y_2 + $signal_bar_spacing")
  signal_4_y_2=$(calcInt "$signal_4_y_1 + $signal_bar_width")
  signal_4_cmd="roundrectangle $signal_4_y_1,$signal_4_x $signal_4_y_2,$signal_img_height $signal_border_radius,$signal_border_radius"

  # create a signal png
  convert -size "${signal_img_width}x${signal_img_height}" xc:transparent \
    -fill "$BLACK_COLOR" \
    -draw "$signal_1_cmd" \
    -draw "$signal_2_cmd" \
    -draw "$signal_3_cmd" \
    -fill "$BLACK_GREY" \
    -draw "$signal_4_cmd" \
    "$SIGNAL_BLACK_PATH"

  convert -size "${signal_img_width}x${signal_img_height}" xc:transparent \
    -fill "$WHITE_COLOR" \
    -draw "$signal_1_cmd" \
    -draw "$signal_2_cmd" \
    -draw "$signal_3_cmd" \
    -fill "$WHITE_GREY" \
    -draw "$signal_4_cmd" \
    "$SIGNAL_WHITE_PATH"

  wifi_img_width="510"
  wifi_img_height="360"

  wifi_strokewidth="70"
  wifi_inner_offset="30"

  wifi_angle="90"

  wifi_1_radius=$(calcInt "$wifi_img_height - $wifi_strokewidth * 0.5")
  wifi_3_radius=$(calcInt "0 + $wifi_strokewidth * 0.5 + $wifi_inner_offset")
  wifi_2_radius=$(calcInt "( $wifi_1_radius + $wifi_3_radius ) / 2")

  wifi_angle_left=$(calcInt "270 - $wifi_angle / 2")
  wifi_angle_right=$(calcInt "$wifi_angle_left + $wifi_angle")

  convert -size "${wifi_img_width}x${wifi_img_height}" xc:transparent \
    -fill "transparent" \
    -stroke "$BLACK_COLOR" \
    -strokewidth "$wifi_strokewidth" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_1_radius,$wifi_1_radius $wifi_angle_left,$wifi_angle_right" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_2_radius,$wifi_2_radius $wifi_angle_left,$wifi_angle_right" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_3_radius,$wifi_3_radius $wifi_angle_left,$wifi_angle_right" \
    -strokewidth "$(calcInt "$wifi_inner_offset * 2")" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height 10,10 $wifi_angle_left,$wifi_angle_right" \
    "$WIFI_BLACK_PATH"

  convert -size "${wifi_img_width}x${wifi_img_height}" xc:transparent \
    -fill "transparent" \
    -stroke "$WHITE_COLOR" \
    -strokewidth "$wifi_strokewidth" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_1_radius,$wifi_1_radius $wifi_angle_left,$wifi_angle_right" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_2_radius,$wifi_2_radius $wifi_angle_left,$wifi_angle_right" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height $wifi_3_radius,$wifi_3_radius $wifi_angle_left,$wifi_angle_right" \
    -strokewidth "$(calcInt "$wifi_inner_offset * 2")" \
    -draw "ellipse $(calcInt "$wifi_img_width / 2"),$wifi_img_height 10,10 $wifi_angle_left,$wifi_angle_right" \
    "$WIFI_WHITE_PATH"

  battery_img_width="820"
  battery_img_height="390"

  battery_strokewidth="25"
  battery_spacing="30"

  battery_outline_width="760"
  battery_outline_height=$(calcInt "$battery_img_height - $battery_strokewidth")
  battery_outline_border_radius="100"

  battery_body_width=$(calcInt "( $battery_outline_width - $battery_strokewidth * 7 ) * $BATTERY_PERCENTAGE / 100")
  battery_body_height=$(calcInt "$battery_outline_height - $battery_strokewidth * 5")
  battery_body_border_radius="50"

  battery_plus_pole_width="40"
  battery_plus_pole_height="65"

  battery_outline_x_1=$(calcInt "$battery_strokewidth / 2")
  battery_outline_y_1=$(calcInt "$battery_strokewidth / 2")

  battery_outline_x_2=$(calcInt "$battery_outline_x_1 + $battery_outline_width - 2 * $battery_strokewidth")
  battery_outline_y_2=$(calcInt "$battery_outline_y_1 + $battery_outline_height")

  battery_body_x_1=$(calcInt "$battery_outline_x_1 + 2 * $battery_spacing")
  battery_body_y_1=$(calcInt "$battery_outline_y_1 + 2 * $battery_spacing")

  battery_body_x_2=$(calcInt "$battery_body_x_1 + $battery_body_width")
  battery_body_y_2=$(calcInt "$battery_body_y_1 + $battery_body_height")

  battery_plus_pole_x=$(calcInt "$battery_outline_x_2 + 2 * $battery_strokewidth")
  battery_plus_pole_y=$(calcInt "$battery_img_height / 2")

  convert -size "${battery_img_width}x${battery_img_height}" xc:transparent \
    -fill "transparent" \
    -stroke "$BLACK_GREY" \
    -strokewidth "$battery_strokewidth" \
    -draw "roundrectangle $battery_outline_x_1,$battery_outline_y_1 $battery_outline_x_2,$battery_outline_y_2 $battery_outline_border_radius,$battery_outline_border_radius" \
    -stroke "$BLACK_COLOR" \
    -fill "$BLACK_COLOR" \
    -draw "roundrectangle $battery_body_x_1,$battery_body_y_1 $battery_body_x_2,$battery_body_y_2 $battery_body_border_radius,$battery_body_border_radius" \
    -fill "$BLACK_GREY" \
    -stroke transparent \
    -draw "ellipse $battery_plus_pole_x,$battery_plus_pole_y $battery_plus_pole_width,$battery_plus_pole_height 270,90" \
    "$BATTERY_BLACK_PATH"

  convert -size "${battery_img_width}x${battery_img_height}" xc:transparent \
    -fill "transparent" \
    -stroke "$WHITE_GREY" \
    -strokewidth "$battery_strokewidth" \
    -draw "roundrectangle $battery_outline_x_1,$battery_outline_y_1 $battery_outline_x_2,$battery_outline_y_2 $battery_outline_border_radius,$battery_outline_border_radius" \
    -stroke "$WHITE_COLOR" \
    -fill "$WHITE_COLOR" \
    -draw "roundrectangle $battery_body_x_1,$battery_body_y_1 $battery_body_x_2,$battery_body_y_2 $battery_body_border_radius,$battery_body_border_radius" \
    -fill "$WHITE_GREY" \
    -stroke transparent \
    -draw "ellipse $battery_plus_pole_x,$battery_plus_pole_y $battery_plus_pole_width,$battery_plus_pole_height 270,90" \
    "$BATTERY_WHITE_PATH"

  SIGNAL_ASPECT_RATIO=$(calcFloat "$(identify -ping -format '%[width]/%[height]\n' "$SIGNAL_BLACK_PATH")" "4")
  WIFI_ASPECT_RATIO=$(calcFloat "$(identify -ping -format '%[width]/%[height]\n' "$WIFI_BLACK_PATH")" "4")
  BATTERY_ASPECT_RATIO=$(calcFloat "$(identify -ping -format '%[width]/%[height]\n' "$BATTERY_BLACK_PATH")" "4")
}

function createBar() {
  out_path="${1:-}"
  width="${2:-}"
  bar_height="${3:-}"
  notch_size="${4:-}"
  icons_height="${5:-}"
  icons_padding="${6:-}"

  [[ -z "$out_path" ]] && echo "\$out_path is empty" && exit -1
  [[ ! -d "$out_path" ]] && echo "\$out_path '$out_path' is not a directory" && exit -1

  size="${width}x${bar_height}"

  font_size="$(calcInt "$icons_height * 1.4")"

  general_x_offset=$(calcInt "(( $width - $notch_size ) / 4) + $notch_size / 2")

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
#  4) the notch width (0 for no notch),
#  5) height of the icons,
#  6) padding between the icons.
# I got the information from closely inspecting
# screenshots taken on simulators.
createBar "$PROGPATH/6.7inch-1290x2796" 1290 92 484 38 24
createBar "$PROGPATH/6.7inch-1284x2778" 1284 92 484 38 24
createBar "$PROGPATH/6.5inch" 1242 86 632 36 19
createBar "$PROGPATH/1125" 1125 86 605 33 15
