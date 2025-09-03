#!/usr/bin/env bash
# Set up search engines
declare -A ENGINES=(
    [":g"]="Google: https://www.google.com/search?q="
    [":d"]="DuckDuckGo: https://duckduckgo.com/?q="
    [":e"]="Ecosia: https://www.ecosia.org/search?q="
    [":b"]="Bing: https://www.bing.com/search?q="
    [":br"]="Brave: https://search.brave.com/search?q="
    [":yt"]="YouTube: https://www.youtube.com/results?search_query="
    [":gh"]="GitHub: https://github.com/search?q="
    [":w"]="Wikipedia: https://en.wikipedia.org/wiki/Special:Search?search="
)

# Utility: URL encode input string
url_encode() {
    local string="$1"
    if command -v jq &>/dev/null; then
        printf '%s' "$string" | jq -sRr @uri
    elif command -v python3 &>/dev/null; then
        printf '%s' "$string" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.stdin.read().strip()))'
    else
        string="${string// /%20}"
        printf '%s' "$string"
    fi
}

# If no argument: list available search engines and tips
if [ $# -eq 0 ]; then
    echo "Type a search (default: Google)."
    echo
    echo "Prefixes for quick search engines:"
    for key in "${!ENGINES[@]}"; do
        engine=${ENGINES[$key]}
        printf '  %s %s\n' "$key" "${engine%%:*}"
    done
    echo
    echo "Example: ':d privacy tools' => DuckDuckGo search"
    exit 0
fi

# Combine all arguments into a single input string
input="$*"
input="$(echo "$input" | xargs)"
prefix="${input%% *}"

if [[ "${ENGINES[$prefix]+_}" ]]; then
    query="${input#* }"
else
    prefix=":g"
    query="$input"
    engine_url="${ENGINES[$prefix]##*: }"
fi

encoded_query=$(url_encode "$query")
url="${engine_url}${encoded_query}"

# Optionally send a desktop notification
if command -v notify-send &>/dev/null; then
    notify-send "Rofi Web Search" "Searching: $query"
fi

# Open the URL with appropriate browser
if [[ "$prefix" == ":yt" ]]; then
    # Use Brave for YouTube searches
    brave "$url" &>/dev/null & disown
else
    # Use default browser for everything else
    qutebrowser "$url" &>/dev/null & disown
fi
