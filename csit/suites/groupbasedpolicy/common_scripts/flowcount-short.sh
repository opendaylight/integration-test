[ "$1" ] || {
    echo "Syntax:"
    echo "flowcount-short.sh <bridge> "
    exit 1
}

printf "%s:" $1
printf $(($( sudo ovs-ofctl dump-flows $1 -OOpenFlow13 | wc -l )-1)) 
printf "["
for i in `seq 0 6`; do
    if [ $i != "0" ]; then printf ","; fi
    printf "%s" $(($(sudo ovs-ofctl dump-flows $1 -OOpenFlow13 table=$i| wc -l )-1))
done
printf "]\n"

