# Convenience script to run check on all .robot files in the project.
# Run with the "quiet" argument to get rid of the non-error output.

if test "${1-loud}" = "quiet"; then
  CHECK="quiet"
else
  CHECK="check"
fi
python tidytool.py $CHECK ../..
