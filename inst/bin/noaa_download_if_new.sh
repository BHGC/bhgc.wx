#! /usr/bin/env bash

error() {
    {
        echo "ERROR: $*"
    } >&2
    exit 1
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
dryrun=${BHGC_NOAA_DRYRUN:-false}
force=${BHGC_NOAA_FORCE:-false}
skip=${BHGC_NOAA_SKIP:-true}

## Options
site=${1}
shift

case "$site" in
    blackcap)
        label="Black Cap (6250 ft), OR"
        lat=36.818344
        lon=-118.0429785
        zcode=ORZ031
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=42.2043&lon=-120.3301&wfo=MFR&zcode=ORZ031&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=12&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    bluerock)
        label="Blue Rock, Vallejo (550 ft), CA"
        lat=38.1384
        lon=-122.1956
        zcode=CAZ018
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=38.1384&lon=-122.1956&wfo=MTR&zcode=CAZ018&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    channing-east)
        label="Channing East, Benicia (660 ft), CA"
        lat=38.101500
        lon=-122.181000
        zcode=CAZ018
        ;;
    dumps)
        label="The Dumps, Pacifica (100 ft), CA"
        lat=37.6722
        lon=-122.4939
        zcode=CAZ509
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=37.6722&lon=-122.4939&wfo=MTR&zcode=CAZ509&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    edlevin-600)
        label="Ed Levin (600 ft), Milpitas, CA"
        lat=37.4613
        lon=-121.8600
        zcode=CAZ511
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=37.4613&lon=-121.86&wfo=MTR&zcode=CAZ511&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    edlevin-1750)
        label="Ed Levin (1750 ft), Milpitas, CA"
        lat=37.4754
        lon=-121.8613
        zcode=CAZ511
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=37.4754&lon=-121.8613&wfo=MTR&zcode=CAZ511&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    hatcreek)
        label="Hat Creek (4500 ft), CA"
        lat=40.843055
        lon=-121.4274685
        zcode=CAZ014
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=40.8431&lon=-121.4275&wfo=STO&zcode=CAZ014&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=12&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    lakecourt)
        label="Lake Court Dune, Marina, CA"
        lat=36.6835
        lon=-121.8114
        zcode=CAZ530
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=36.6835&lon=-121.8114&wfo=MTR&zcode=CAZ530&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    mission)
        label="Mission Ridge (1900 ft), Freemont, CA"
        lat=37.517534
        lon=-121.89175
        zcode=CAZ509
        ## view-source:https://forecast.weather.gov/meteograms/Plotter.php?lat=37.6722&lon=-122.4939&wfo=MTR&zcode=CAZ509&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=12&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    mttam-b)
        label="Mt Tam, (Launch B; 1950 ft), Stinson Beach, CA"
        lat=37.9112
        lon=-122.6244
        zcode=CAZ507
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=37.9112&lon=-122.6244&wfo=MTR&zcode=CAZ507&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    slide)
        label="Slide Mountain (8200 ft), NV"
        lat=39.3199
        lon=-119.8674
        zcode=NVZ002
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=39.3199&lon=-119.8674&wfo=REV&zcode=NVZ002&gset=18&gdiff=8&unit=0&tinfo=PY8&ahour=0&pcmd=11011111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    sugarhill)
        label="Sugar Hill (7200 ft), CA"
        lat=41.806521
        lon=-120.328989
        zcode=CAZ085
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=41.8065&lon=-120.329&wfo=MFR&zcode=CAZ085&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=12&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    sweetandlow)
        label="Sweet and Low (5650 ft), CA"
        lat=41.828500
        lon=-120.346483
        zcode=CAZ085
        ## https://forecast.weather.gov/meteograms/Plotter.php?lat=41.8285&lon=-120.3465&wfo=MFR&zcode=CAZ085&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=12&pcmd=11101111111110000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=0&bw=0&hrspan=48&pqpfhr=6&psnwhr=6
        ;;
    *)
        error "Unknown site: $site"
esac

debug "Current time: $(date --rfc-3339=seconds)"
debug "site=${site}"
debug "label=${label}"
debug "lat=${lat}"
debug "lon=${lon}"
debug "zcode=${zcode}"
debug "to=$*"
debug "dryrun=${dryrun}"
debug "force=${force}"
debug "skip=${skip}"

root=$HOME/.cache/bhgc/sites
create_dir "$root"

path="${root}/${site}"
create_dir "$path"
debug "path=${path}"

url="https://forecast.weather.gov/MapClick.php?lat=${lat}&lon=${lon}&FcstType=digitalDWML"
debug "XML URL: ${url}"

tf=$(mktemp)
curl --silent -o "${tf}" "${url}"

timestamp=$(grep creation-date "${tf}" | sed -E 's/[ ]*<creation-date[^>]*>([^<]+)<.*/\1/g')
[[ -z "${timestamp}" ]] && error "Failed to retrieve forecast for site=$site"
debug "timestamp=${timestamp}"

wfo=$(basename "$(grep credit "${tf}" | sed -E 's/[ ]*<credit[^>]*>([^<]+)<.*/\1/g')")
debug "wfo=${wfo}"
[[ -z "${wfo}" ]] && error "Failed to infer WFO (weather forecast office) for site=$site"

xml="${path}/${site},${timestamp},${wfo}.xml"
debug "xml=${xml}"

## Already downloaded?
if ! $force && $skip && [[ -f "${xml}" ]]; then
    debug "Skipping. Already downloaded: ${xml}"
    rm "${tf}"
    exit 0
fi

url="https://forecast.weather.gov/meteograms/Plotter.php?lat=${lat}&lon=${lon}&wfo=${wfo}&zcode=${zcode}&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111110000000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=&bw=0&hrspan=48&pqpfhr=6&psnwhr=6"
debug "PNG URL: ${url}"
png="${path}/${site},${timestamp},${wfo}.png"
## Already downloaded?
if ! $force && [[ -f "${png}" ]]; then
    debug "Skipping because already downloaded: ${png}"
else
    debug "Downloading PNG file"
    curl --silent -o "${png}" "${url}"
fi
debug "PNG file: $(ls -l "${png}")"

if ! $force && $skip && [[ -f "${xml}" ]]; then
    [[ -f "${tf}" ]] && rm "${tf}"
else
    mv "${tf}" "${xml}"
fi
debug "XML file: $(ls -l "${xml}")"

## Email?
if [[ $# -gt 0 ]]; then
    debug "Composing email:"
    debug "Additional options to 'mail': $*"
    subject="NOAA: ${label}"
    debug "subject=${subject}"
    date=$(echo "${timestamp}" | sed -E 's/(.*)T(.*)([-+].*)/\1/g')
    time=$(echo "${timestamp}" | sed -E 's/(.*)T(.*)([-+].*)/\2/g')
    utc=$(echo "${timestamp}" | sed -E 's/(.*)T(.*)([-+].*)/\3/g')
    NL=$'\n'
    body="New NOAA weather forecast for ${label} at ${time} on ${date} (UTC ${utc}) by the ${wfo^^} office.${NL}"
    if [[ -n "${BHGC_NOAA_CONDITIONS}" ]]; then
        body="${body}${NL}* ${BHGC_NOAA_CONDITIONS}${NL}"
    fi
    url="https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&Submit=Submit&&site=mtr&bw=0&textField1=${lat}&textField2=${lon}&AheadHour=0&FcstType=graphical"
    body="${body}${NL}* ${url}${NL}"    
    url="https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&Submit=Submit&&site=mtr&bw=0&textField1=${lat}&textField2=${lon}&AheadHour=0&FcstType=digital"
    body="${body}${NL}* ${url}${NL}"
    url="https://forecast.weather.gov/product.php?site=${wfo^^}&issuedby=${wfo^^}&product=AFD&format=TXT&glossary=1"
    body="${body}${NL}* ${url}${NL}"
#    body="${body}${NL}${NL}This message was sent on $(date --rfc-3339=seconds)${NL}"
    debug "body=${NL}${body}"
    
    debug "Email command: printf \"%s\" \"\${body}\" | mail -a \"\${png}\" -s \"\${subject}\" $*"
    if $dryrun; then
        debug "Email result: N/A (dryrun=true)"
    else
        # shellcheck disable=SC2086,SC2048
        printf "%s" "${body}" | mail -a "${png}" -s "${subject}" $*
        debug "Email result: $?"
    fi

    if [[ -n "${R_BHGC_NOAA_EMAIL_CREDENTIALS}" ]]; then
        debug "HTML email:"
        Rscript -e bhgc.wx::send_email --args --label="${label}" --lon="${lon}" --lat="${lat}" --wfo="${wfo}" --timestamp="${timestamp}" --imgfile="${png}" --from="${BHGC_NOAA_FROM}" --to="${BHGC_NOAA_TO}" --bcc="${BHGC_NOAA_BCC}"
    fi
fi
