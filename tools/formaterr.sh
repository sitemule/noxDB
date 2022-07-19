
 
cat $1 | iconv -f 500 -t 819 | fold  --width=300 | grep '^ERROR' | grep -v 'RNF7031' | grep -v 'RNF5409' | \
while read line; do
    msg=$(echo "$line" | cut -c66-150);
    msgid=$(echo "$line" | cut -c49-55);
    linno=$(echo "$line" | cut -c21-25);
    col=$(echo "$line" | cut -c34-36);
    sev=$(echo "$line" | cut -c57-57);
    echo "$msgid:$msg:$linno:$col:$sev:$2";
done
