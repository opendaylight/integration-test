prefix="pps";
result="result";
format="png";

csv_file_name=$result$prefix.csv

i=1;
for f in $prefix*.csv;
do
  if [ $i -eq 1 ]
    then
      sed -n 1p $f;
  fi
  printf "$i,";
  sed -n 2p $f;
  i=$((i+1));
done > $csv_file_name

plot_file_name=$result$prefix.$format
echo "set datafile separator \",\"
set term $format 
set output \"$plot_file_name\"
set key autotitle columnhead 
plot \"$csv_file_name\" using 1:2 with linespoints, \"$csv_file_name\" using 1:3 with linespoints, \"$csv_file_name\" using 1:4 with linespoints" | gnuplot
