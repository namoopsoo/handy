
file=$1
echo "file: $file" ; arr=($file); 
first=${arr[0]};
echo "first thing $first" ; 
for file in ${first}*; 
	do echo  "============="; 
    echo "$file";echo "============="; 
    cat "$file";echo  ; 
done
