# Convenience script to run check on all .robot files in the project.
# Run with the "quiet" argument to get rid of the non-error output.

if test "${1-loud}" = "quiet"; then
  COMMAND="quiet"
elif test "${1-loud}" = "tidy"; then
  COMMAND="tidy"
else
  COMMAND="check"
fi
BASE=`dirname ${0}`
cd $BASE
BASE=`pwd`
cd ../..
DIRLIST=""
for Dir in *; do
  if test -d $Dir; then
    DIRLIST="$DIRLIST $Dir"
  fi
done
python $BASE/tidytool.py $COMMAND $DIRLIST
