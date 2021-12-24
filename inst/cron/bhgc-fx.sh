#! /usr/bin/env bash
### fx check
### 
### Usage:
###  bhgc-fx <command> [option]*
### 
### Commands:
###  check   Check for FX update for a site
###  view    View most recent FX for a site 
###  sites   List known sites
###
### Sites:
### {{table_of_sites}}
###
### Options:
###  --help
###  --version
###  --debug
###  --force
###  --site=<site>
###  --email_from=<email address>  
###  --email_to=<email address>    
###  --email_bcc=<email address>    
###
### Example:
###  bhgc-fx --help
###  bhgc-fx --version
###  bhgc-fx sites
###  bhgc-fx check --site=mttam-b
###
### Environment variables:
###  R_BHGC_NOAA_EMAIL_CREDENTIALS
###  BHGC_NOAA_FROM
###  BHGC_NOAA_TO
###  BHGC_NOAA_BCC
###  BHGC_NOAA_CONDITIONS
###
### Requirements:
###  * curl
###  * mail
###
### Version: 0.1.0-9000
### Copyright: Henrik Bengtsson (2019-2021)
### License: MIT

# -------------------------------------------------------------------------
# Output utility functions
# -------------------------------------------------------------------------
_tput() {
    if [[ $theme == "none" ]]; then
        return
    fi
    tput "$@" 2> /dev/null
}

mecho() { echo "$@" 1>&2; }
mdebug() {
    if ! $debug; then
        return
    fi
    {
        _tput setaf 8 ## gray
        echo "DEBUG: $*"
        _tput sgr0    ## reset
    } 1>&2
}
merror() {
    local info version
    {
        info="ucsf-vpn $(version)"
        version=$(openconnect_version 2> /dev/null)
        if [[ -n $version ]]; then
            info="$info, OpenConnect $version"
        else
            info="$info, OpenConnect version unknown"
        fi
        [[ -n $info ]] && info=" [$info]"
        _tput setaf 1 ## red
        echo "ERROR: $*$info"
        _tput sgr0    ## reset
    } 1>&2
    _exit 1
}

mwarn() {
    {
        _tput setaf 3 ## yellow
        echo "WARNING: $*"
        _tput sgr0    ## reset
    } 1>&2
}
minfo() {
    if ! $verbose; then
        return
    fi
    {
        _tput setaf 4 ## blue
        echo "INFO: $*"
        _tput sgr0    ## reset
    } 1>&2
}
mok() {
    {
        _tput setaf 2 ## green
        echo "OK: $*"
        _tput sgr0    ## reset
    } 1>&2
}
mdeprecated() {
    {
        _tput setaf 3 ## yellow
        echo "DEPRECATED: $*"
        _tput sgr0    ## reset
    } 1>&2
}
mnote() {
    {
        _tput setaf 11  ## bright yellow
        echo "NOTE: $*"
        _tput sgr0    ## reset
    } 1>&2
}

_exit() {
    local value

    value=${1:-0}
    mdebug "Exiting with exit code $value"
    exit "$value"
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# OUTPUT
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Use colored stdout if the terminal supports it
## and as long as a stdout are not redirected
term_colors() {
    local action
    local what
    
    action=$1
    what=$2
    [[ -z "${what}" ]] && what=1
    
    if [[ "${action}" == "enable" && -t "${what}" ]]; then
        ## ANSI foreground colors
        black=$(tput setaf 0)
        red=$(tput setaf 1)
        green=$(tput setaf 2)
        yellow=$(tput setaf 3)
        blue=$(tput setaf 4)
        magenta=$(tput setaf 5)
        cyan=$(tput setaf 6)
        white=$(tput setaf 7)

        ## Text modes
        bold=$(tput bold)
        dim=$(tput dim)
        reset=$(tput sgr0)
    else
        export black=
        export red=
        export green=
        export yellow=
        export blue=
        export magenta=
        export cyan=
        export white=

        export bold=
        export dim=

        export reset=
    fi
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# CONDITIONS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
error() {
    local red
    local gray
    local bold
    local reset
    
    ON_ERROR=${ON_ERROR:-on_error}
    TRACEBACK_ON_ERROR=${TRACEBACK_ON_ERROR:-true}
    EXIT_ON_ERROR=${EXIT_ON_ERROR:-true}
    EXIT_VALUE=${EXIT_VALUE:-1}

    ## Parse arguments
    while [ -n "$1" ]; do
        case "$1" in
            --dryrun) EXIT_ON_ERROR=false; shift;;
            --value=*) EXIT_VALUE="${1/--value=/}"; shift;;
            *) break;;
        esac
    done

    if [[ -t 1 ]]; then
        red=$(tput setaf 1)
        gray=$(tput setaf 8)
        bold=$(tput bold)
        reset=$(tput sgr0)
    fi

    echo -e "${red}${bold}ERROR:${reset} ${bold}$*${reset}"

    if ${TRACEBACK_ON_ERROR}; then
       echo -e "${gray}Traceback:"
       for ((ii = 1; ii < "${#BASH_LINENO[@]}"; ii++ )); do
           printf "%d: %s() on line #%s in %s\\n" "$ii" "${FUNCNAME[$ii]}" "${BASH_LINENO[$((ii-1))]}" "${BASH_SOURCE[$ii]}"
       done
    fi

    if [[ -n "${ON_ERROR}" ]]; then
        if [[ $(type -t "${ON_ERROR}") == "function" ]]; then
            ${ON_ERROR}
        fi
    fi

    ## Exit?
    if ${EXIT_ON_ERROR}; then
        echo -e "Exiting (exit ${EXIT_VALUE})${reset}";
        exit "${EXIT_VALUE}"
    fi

    printf "%s" "${reset}"
}

warn() {
    local yellow
    local reset
    
    TRACEBACK_ON_WARN=${TRACEBACK_ON_WARN:-false}
    
    if [[ -t 1 ]]; then
        yellow=$(tput setaf 3)
        bold=$(tput bold)
        reset=$(tput sgr0)
    fi
    
    echo -e "${yellow}${bold}WARNING${reset}: $*"
    
    if ${TRACEBACK_ON_WARN}; then
       echo -e "${gray}Traceback:"
       for ((ii = 1; ii < "${#BASH_LINENO[@]}"; ii++ )); do
           printf "%d: %s() on line #%s in %s\\n" "$ii" "${FUNCNAME[$ii]}" "${BASH_LINENO[$((ii-1))]}" "${BASH_SOURCE[$ii]}"
       done
    fi
    
    printf "%s" "${reset}"
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ASSERTIONS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Usage: assert_file_exists /path/to/file
assert_file_exists() {
    [[ $# -ne 1 ]] && error "${FUNCNAME[0]}() requires a single argument: $#"
    [[ -n "$1" ]] || error "File name must be non-empty: '$1'"
    [[ -f "$1" ]] || error "No such file: '$1' (working directory '${PWD}')"
}

assert_link_exists() {
    [[ $# -ne 1 ]] && error "${FUNCNAME[0]}() requires a single argument: $#"
    [[ -n "$1" ]] || error "File name must be non-empty: '$1'"
    [[ -L "$1" ]] || error "File is not a link: '$1' (working directory '${PWD}')"
    [[ -e "$1" ]] || error "[File] link is broken: '$1' (working directory '${PWD}')"
}

## Usage: assert_file_executable /path/to/file
assert_file_executable() {
    [[ $# -ne 1 ]] && error "${FUNCNAME[0]}() requires a single argument: $#"
    assert_file_exists "$1"
    [[ -x "$1" ]] || error "File exists but is not executable: '$1' (working directory '${PWD}')"
}

## Usage: assert_directory_exists /path/to/folder
assert_directory_exists() {
    [[ $# -ne 1 ]] && error "${FUNCNAME[0]}() requires a single argument: $#"
    [[ -n "$1" ]] || error "Directory name must be non-empty: '$1'"
    [[ -d "$1" ]] || error "No such directory: '$1' (working directory '${PWD}')"
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NAVIGATION
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
change_dir() {
    opwd=${PWD}
    assert_directory_exists "$1"
    cd "$1" || error "Failed to set working directory to $1"
    echo "New working directory: '$1' (was '${opwd}')"
}

make_dir() {
    mkdir -p "$1" || error "Failed to create new working directory $1"
}

equal_dirs() {
    local a
    local b
    a=$(readlink -f "$1")
    b=$(readlink -f "$2")
    [[ "${a}" == "${b}" ]]
}


# -------------------------------------------------------------------------
# CLI utility functions
# -------------------------------------------------------------------------
version() {
    grep -E "^###[ ]*Version:[ ]*" "$0" | sed 's/###[ ]*Version:[ ]*//g'
}

help() {
    local what res t

    what=$1

    t=$(table_of_sites)
    t=${t//$'\n'/\\n}
    res=$(grep "^###" "$0" | grep -vE '^(####|### whatis: )' | cut -b 5- | sed "s/{{table_of_sites}}/$t/")

    if [[ $what == "full" ]]; then
        res=$(echo "$res" | sed '/^---/d')
    else
        res=$(echo "$res" | sed '/^---/Q')
    fi

    printf "%s\\n" "${res[@]}"
}


# -------------------------------------------------------------------------
# FX functions
# -------------------------------------------------------------------------
list_sites() {
    assert_file_exists "$0"
    grep -E "^[[:space:]]+[a-z0-9-]+[)][[:space:]]*$" "$0" | sed -E 's/[[:space:])]//g'
}

table_of_sites() {
    local site
    for site in $(list_sites); do
        printf " %-8s\\n" "$site"
    done
}

view_image() {
    assert_file_exists "$1"
    xdg-open "$1"
}


# -------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------
theme=
debug=${BHGC_NOAA_DEBUG:-false}
dryrun=${BHGC_NOAA_DRYRUN:-false}
force=${BHGC_NOAA_FORCE:-false}
skip=${BHGC_NOAA_SKIP:-true}
action=
site=
extras=
email_from=${BHGC_NOAA_FROM}
email_to=${BHGC_NOAA_TO}
email_bcc=${BHGC_NOAA_BCC}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    mdebug "Next CLI argument: $1"
    ## Commands:
    if [[ "$1" == "check" ]]; then
        action="$1"
    elif [[ "$1" == "sites" ]]; then
        action="$1"
    elif [[ "$1" == "view" ]]; then
        action="$1"

    ## Options (--flags):
    elif [[ "$1" == "--help" ]]; then
        action=help
    elif [[ "$1" == "--version" ]]; then
        action=version
    elif [[ "$1" == "--debug" ]]; then
        debug=true
    elif [[ "$1" == "--dryrun" ]]; then
        dryrun=true
    elif [[ "$1" == "--force" ]]; then
        force=true
    elif [[ "$1" == "--skip" ]]; then
        skip=true
    elif [[ "$1" == "--verbose" ]]; then
        verbose=1
    
    ## Options (--key=value):
    elif [[ "$1" =~ ^--.*=.*$ ]]; then
        key=${1//--}
        key=${key//=*}
        value=${1//--[[:alpha:]]*=}
        mdebug "Key-value option '$1' parsed to key='$key', value='$value'"
        if [[ -z $value ]]; then
            merror "Option '--$key' must not be empty"
        fi
        if [[ "$key" == "site" ]]; then
            site=$value
        elif [[ "$key" == "email-from" ]]; then
            email_from=$value
        elif [[ "$key" == "email-to" ]]; then
            email_to=$value
        elif [[ "$key" == "email-bcc" ]]; then
            email_bcc=$value
        elif [[ "$key" == "skip" ]]; then
            skip=$value
        fi
    else
        extras="extras $1"
    fi
    shift
done


mdebug "action: '${action}'"
mdebug "debug: ${debug}"
mdebug "dryrun: ${dryrun}"
mdebug "force: ${force}"
mdebug "skip: ${skip}"
mdebug "extras: '${extras}'"

## --help should always be available prior to any validation errors
if [[ -z $action ]]; then
    help
    _exit 0
elif [[ $action == "help" ]]; then
    help full
    _exit 0
elif [[ $action == "version" ]]; then
    version
    _exit 0
fi


if [[ $action == "sites" ]]; then
    list_sites
    _exit 0
fi


[[ -z "${site}" ]] && error "No site specified"

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
        error "Not one of the known sites ($(list_sites | tr $'\n' ' ' | sed -E 's/ $//g')): $site"
esac

mdebug "Current time: $(date --rfc-3339=seconds)"
mdebug "site=${site}"
mdebug "label=${label}"
mdebug "lat=${lat}"
mdebug "lon=${lon}"
mdebug "zcode=${zcode}"

root=$HOME/.cache/bhgc/sites
make_dir "$root"

path="${root}/${site}"
make_dir "$path"
mdebug "path=${path}"

if [[ $action == "view" ]]; then
    mapfile -t files < <(find "${path}" -type f -name "*.png" -printf "\n%AY-%Am-%AdT%AH%AM%AS %p" | sort --reverse --key=1)
    [[ ${#files} -eq 0 ]] && error "There are no downloaded forecasts for site '${site}': ${path}"
    file=$(echo "${files[0]}" | cut -d ' ' -f 2)
    mdebug "More recent file: ${file}"
    view_image "$file"
    _exit 0
fi

[[ $action == "check" ]] || error "INTERNAL ERROR: action=${action}"

url="https://forecast.weather.gov/MapClick.php?lat=${lat}&lon=${lon}&FcstType=digitalDWML"
mdebug "XML URL: ${url}"

tf=$(mktemp)
curl --silent -o "${tf}" "${url}"

timestamp=$(grep creation-date "${tf}" | sed -E 's/[ ]*<creation-date[^>]*>([^<]+)<.*/\1/g')
[[ -z "${timestamp}" ]] && error "Failed to retrieve forecast for site=$site"
mdebug "timestamp=${timestamp}"

wfo=$(basename "$(grep credit "${tf}" | sed -E 's/[ ]*<credit[^>]*>([^<]+)<.*/\1/g')")
mdebug "wfo=${wfo}"
[[ -z "${wfo}" ]] && error "Failed to infer WFO (weather forecast office) for site=$site"

xml="${path}/${site},${timestamp},${wfo}.xml"
mdebug "xml=${xml}"

## Already downloaded?
if ! $force && $skip && [[ -f "${xml}" ]]; then
    mdebug "Skipping. Already downloaded: ${xml}"
    rm "${tf}"
    exit 0
fi

url="https://forecast.weather.gov/meteograms/Plotter.php?lat=${lat}&lon=${lon}&wfo=${wfo}&zcode=${zcode}&gset=18&gdiff=3&unit=0&tinfo=PY8&ahour=0&pcmd=11101111110000000000000000000000000000000000000000000000000&lg=en&indu=1!1!1!&dd=&bw=0&hrspan=48&pqpfhr=6&psnwhr=6"
mdebug "PNG URL: ${url}"
png="${path}/${site},${timestamp},${wfo}.png"
## Already downloaded?
if ! $force && [[ -f "${png}" ]]; then
    mdebug "Skipping because already downloaded: ${png}"
else
    mdebug "Downloading PNG file"
    curl --silent -o "${png}" "${url}"
fi
mdebug "PNG file: $(ls -l "${png}")"

if ! $force && $skip && [[ -f "${xml}" ]]; then
    [[ -f "${tf}" ]] && rm "${tf}"
else
    mv "${tf}" "${xml}"
fi
mdebug "XML file: $(ls -l "${xml}")"

## Email?
if [[ $# -gt 0 ]]; then
    mdebug "Composing email:"
    mdebug "Additional options to 'mail': ${extras}"
    subject="NOAA: ${label}"
    mdebug "subject=${subject}"
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
    mdebug "body=${NL}${body}"
    
    mdebug "Email command: printf \"%s\" \"\${body}\" | mail -a \"\${png}\" -s \"\${subject}\" $extras"
    if $dryrun; then
        mdebug "Email result: N/A (dryrun=true)"
    else
        # shellcheck disable=SC2086,SC2048
        printf "%s" "${body}" | mail -a "${png}" -s "${subject}" $extras
        mdebug "Email result: $?"
    fi

    if [[ -n "${R_BHGC_NOAA_EMAIL_CREDENTIALS}" ]]; then
        mdebug "HTML email:"
        Rscript -e bhgc.wx::send_email --args --label="${label}" --lon="${lon}" --lat="${lat}" --wfo="${wfo}" --timestamp="${timestamp}" --imgfile="${png}" --from="${email_from}" --to="${email_to}" --bcc="${email_bcc}"
    fi
fi
