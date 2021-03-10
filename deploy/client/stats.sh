echo '{"action" : "stats", "params" : {}}' | socat -t 5 -T 5 - tcp4-connect:localhost:7768

