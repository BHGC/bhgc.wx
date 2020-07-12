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

debug() {
    $debug && {
        echo "DEBUG: $*"
    } >&2
}

create_dir() {
  [[ -d "$1" ]] || mkdir -p "$1" || error "Failed to create folder: $1"
}


[[ $# -eq 0 ]] && error "No site specified"

debug=${BHGC_NOAA_DEBUG:-false}

## Options
site=${1}
shift

case "$site" in
    bluerock)
	label="Blue Rock, Vallejo, CA"
        lat=38.138440
        lon=-122.195634
	;;
    dumps)
	label="The Dumps, Pacifica, CA"
        lat=37.672164
        lon=-122.493943
	;;
    edlevin-600)
	label="Ed Levin (600 ft), Milpitas, CA"
        lat=37.461324
        lon=-121.859979
	;;
    edlevin-1750)
	label="Ed Levin (1750 ft), Milpitas, CA"
        lat=37.475389
        lon=-121.861305
	;;
    lakecourt)
	label="Lakecourt Dune, Marina, CA"
        lat=38.1384
        lon=-122.1956
	;;
    mttam-b)
	label="Mt Tam, (Launch B), Stinson Beach, CA"
        lat=37.911167
        lon=-122.624422
	;;
    *)
	error "Unknown site: $site"
esac

debug "site=${site}"
debug "label=${label}"
debug "lat=${lat}"
debug "lon=${lon}"
debug "to=$*"

root=$HOME/.cache/bhgc/sites
create_dir "$root"

path="${root}/${site}"
create_dir "$path"
debug "path=${path}"

url="https://forecast.weather.gov/MapClick.php?lat=${lat}&lon=${lon}&FcstType=digitalDWML"
debug "url=${url}"

tf=$(mktemp)
curl --silent -o "${tf}" "${url}"

timestamp=$(grep creation-date "${tf}" | sed -E 's/[ ]*<creation-date[^>]*>([^<]+)<.*/\1/g')
[[ -z "${timestamp}" ]] && error "Failed to retrieve forecast for site=$site"
debug "timestamp=${timestamp}"

xml="${path}/${site},${timestamp}.xml"
debug "xml=${xml}"

## Already downloaded
[[ -f "$xml" ]] && { rm "$tf"; exit 0; }

#url="https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&&site=mtr&bw=0&textField1=${lat}&textField2=${lon}&AheadHour=0&FcstType=graphical"
#html="${path}/${timestamp}.html"
#curl --silent -o "${html}" "${url}"

url="https://forecast.weather.gov/meteograms/Plotter.php?lat=${lat}&lon=${lon}&wfo=STO&zcode=CAZ018&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=&bw=0&hrspan=48&pqpfhr=6&psnwhr=6"
png="${path}/${site},${timestamp}.png"
curl --silent -o "${png}" "${url}"

mv "${tf}" "${xml}"

## Email?
if [[ $# -gt 0 ]]; then
    debug "Sending email to $*"
    subject="NOAA Forecast for ${label}"
    debug "subject=${subject}"
    NL=$'\n'
    body="New NOAA weather forecast for ${label} from ${timestamp}.${NL}"
    url="https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&&site=mtr&bw=0&textField1=${lat}&textField2=${lon}&AheadHour=0&FcstType=graphical"
    body="${body}${NL}* ${url}${NL}"    
    url="https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&&site=mtr&bw=0&textField1=${lat}&textField2=${lon}&AheadHour=0&FcstType=digital"
    body="${body}${NL}* ${url}${NL}"    
    # shellcheck disable=SC2086,SC2048
    printf "%s" "${body}" | mail -a "${png}" -s "${subject}" $*
fi
