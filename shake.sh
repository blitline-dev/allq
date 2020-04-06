#!/bin/bash
input="big.txt"
while IFS= read -r line
hh=$(echo $line | base64)
do
  echo "{\"action\" : \"put\", \"params\" : {\"tube\" : \"jason\", \"body\" : \"$hh\"}}" | socat - tcp4-connect:localhost:7766
#  echo '{"action" : "put", "params" : {"tube" : "jason", "body", "$hh"}}' | socat - tcp4-connect:localhost:7766
 
done < "$input"


