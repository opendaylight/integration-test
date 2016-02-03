# Search the specified directory (parameter $1) for the specified items (the
# remaining parameters). The "item" is expected to be a directory located
# somewhere along the directory tree at which $1 points. This directory must
# have exactly 1 subdirectory and that subdirectory's name is considered to
# be the version number we are looking for.
#
# This tool searches for these items in the order specified and emits the
# first version number it finds. Using an one-line shell script for this task
# turned out to be pretty impossible as the algorithm is quite complicated
# (the "items" may move around the directory tree between releases and even
# some of them might disappear and the others appear) so a full blown utility
# is necessary.

exec 2>&1
set -e
directory=$1
shift
if test -d $directory; then :; else
  echo "Path '$directory' does not exist or is not a directory"
  exit 1
fi
if test -d $directory/org/opendaylight; then :; else
  echo "Path '$directory' does not look like OpenDaylight System directory"
  exit 1
fi
file_list=`pwd`/filelist.tmp
trap "rm -f $file_list" EXIT
version_found="n/a"
finish=false
for Thing in $@; do
  cd $directory
  find . -name $Thing -type d -print >$file_list
  exec <$file_list
  while read -r directory_to_check; do
    cd $directory_to_check
    for file_in_checked_directory in *; do
      if test -d $file_in_checked_directory; then
        if test "$version_found" = "n/a"; then
          version_found=$file_in_checked_directory
          where_found=$directory_to_check
          finish=true
        else
          version_found="n/a"
          finish=false
          break
        fi
      fi
    done
    if $finish; then
      break
    fi
  done
  if $finish; then
    break
  fi
done
if $finish; then
  echo $version_found
  dirname $where_found | cut -b 3-
else
  echo "None of the supplied components were found."
  exit 1
fi
