#! /usr/bin/env bash

error() {
    {
        echo "ERROR: $*"
    } >&2
    exit 1
}

skip() {
    {
        echo "SKIP: $*"
    } >&2
    exit 0
}

create_dir() {
  [[ -d "$1" ]] || mkdir -p "$1" || error "Failed to create folder: $1"
}


## Options
lat=${1:-38.1384}
lon=${2:--122.1956}
to=${3}
echo "lat=$lat"
echo "lat=$lon"
echo "to=$to"

root=$HOME/.cache/bhgc/sites
create_dir "$root"

site="lat=${lat},lon=${lon}"
path="${root}/${site}"
create_dir "$path"


url="https://forecast.weather.gov/MapClick.php?lat=${lat}&lon=${lon}&FcstType=digitalDWML"

tf=$(mktemp)
curl --silent -o "${tf}" "${url}"

timestamp=$(grep creation-date "${tf}" | sed -E 's/[ ]*<creation-date[^>]*>([^<]+)<.*/\1/g')
xml="${path}/${timestamp}.xml"

## Already downloaded
[[ -f "$xml" ]] && { rm "$tf"; exit 0; }

#url="https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&&site=mtr&bw=0&textField1=${lat}&textField2=${lon}&AheadHour=0&FcstType=graphical"
#html="${path}/${timestamp}.html"
#curl --silent -o "${html}" "${url}"

url="https://forecast.weather.gov/meteograms/Plotter.php?lat=${lat}&lon=${lon}&wfo=STO&zcode=CAZ018&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=&bw=0&hrspan=48&pqpfhr=6&psnwhr=6"
png="${path}/${timestamp}.png"
curl --silent -o "${png}" "${url}"

mv "${tf}" "${xml}"

## Email?
if [[ -n "$to" ]]; then
    body="New NOAA weather forecast for (${lat},${lon}) from ${timestamp}. See attached figure."
    echo "$body" | mail -s "NOAA Forecast update for (${lat},${lon})" "$to"
fi

