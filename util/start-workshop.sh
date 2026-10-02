#!/bin/bash

# Don't let a failed forwarder or wait step take down the whole container
set +e

# default compose if not spec'd
COMPOSE_FILE="/home/rootless/docker-compose.yml"

echo "Waiting for DinD TLS certificates..."

# Wait until certificate files exist in /certs/client
until [ -f /certs/client/cert.pem ] && [ -f /certs/client/key.pem ] && [ -f /certs/client/ca.pem ]; do
    sleep 1
done

echo "DinD TLC certificates have been generated."

echo "Waiting for DinD..."

until docker info >/dev/null 2>&1; do
    sleep 1
done

echo "DinD is ready."

echo "Reading ports from docker-compose.yml..."

# align dind and workshop loopbacks
if [ -f "$COMPOSE_FILE" ]; then
    # From the dind service's ports section, emit "listen:target" pairs
    PORTS=$(awk '
      /^  dind:/ { in_dind=1; next }
      in_dind && /^  [a-zA-Z]/ { in_dind=0 }
      in_dind && /^    ports:/ { in_ports=1; next }
      in_dind && in_ports && /^    [a-zA-Z]/ { in_ports=0 }
      in_dind && in_ports && /^[[:space:]]*-/ {
        gsub(/[" \t]/, "")
        sub(/#.*/, "")
        sub(/^-/, "")
        n = split($0, parts, ":")
        if (n >= 2 && parts[n] != "" && parts[n-1] != "") print parts[n] ":" parts[n-1]
      }
    ' "$COMPOSE_FILE")
fi

if [ -z "$PORTS" ]; then
    echo "Warning: no ports found in $COMPOSE_FILE. Falling back to default ports."
    PORTS="10080:80 10081:81 11080:1080 13001:3001 13306:3306 19229:9229"
fi

echo "Starting port forwarders..."

for pair in $PORTS; do
    listen=${pair%%:*}
    target=${pair##*:}
    echo "Forwarding :${listen} → 127.0.0.1:${target}"
    socat TCP-LISTEN:${listen},bind=0.0.0.0,fork,reuseaddr TCP:127.0.0.1:${target} &
done

echo "Port forwarding active."

echo
printf '%s\n' \
"             _.----\"\"\"\"\"-.._" \
" __        ._'_ _          '." \
"/  \      / \` \` \`'-.        \`\\" \
"|   \/|   \_ ___ _  \`\        \\" \
"\  _..;    )\` _ \`_\"--.\       |" \
";\"     \   |  a/ a    (\`\     |" \
"|    _.;   /_.<._..___, )\\\\    |" \
"\_.-'  |  ;-.__,__..-'  '.'.  /" \
"  |    ;  /            (  ) \_|" \
"  |     \(   (      (     )/   \\" \
"   \     (       (       .'\   /" \
"    \ ,   \           _.'   '-'\`." \
"     \`|    '-(.___.--' ,;,-\_,   \\" \
"      |         o:  .-'(())_/     ;" \
"      ;          :  |.-'  / \`'.   |" \
"       \        o:  \   .-\    \ _/" \
"        ;--._   _:_  \ /   \    |\\" \
"        )    \`'|.-.|\"'\\\\__.-\`'-'\|" \
"       /\`\`'-.._||_||_..\      _.'." \
"      /        '-;-'    \__.-'  \\" \
"    /\`\`'--..__   :       __..--'\`\`\\" \
"    \_        \`\`\`\`\`\`\`\`\`\`\`        _/" \
"      \`'--,...__       __...,--'\`" \
"          |     \`\`\`;\`\`\`     |" \
"          \        |        /" \
"           \_ _  _ | _ _ _ /" \
"           /\` \` \` \`|\` \` \` \`\\" \
"           \_._._./ \._._._/" \
"            |=    | |    =|" \
"         .--'-.   | |   .-'--." \
"        /         | |         \\" \
"        \______,__/ \__,______/"

echo
echo  "🎅 Workshop up!  Attach Visual Studio Code now."

# Keep workshop elves working
exec tail -f /dev/null