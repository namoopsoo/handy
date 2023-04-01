# (helper script for quickly displaying logseq journal files that have forked off)
# Takes as a parameter a filename that has spaces in it,
#   applies a glob to the first substring when splitting by spaces, 
#   and cat all the files that are available when using that glob.
file=$1
echo "file: $file" ; arr=($file); 
first=${arr[0]};
echo "first thing $first" ; 
for file in ${first}*; 
	do echo  "============="; 
    echo "$file";echo "============="; 
    cat "$file";echo  ; 
done
