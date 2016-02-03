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
Dir=$1
shift
if test -d $Dir; then :; else
  echo "Path '$Dir' does not exist or is not a directory"
  exit 1
fi
if test -d $Dir/org/opendaylight; then :; else
  echo "Path '$Dir' does not look like OpenDaylight System directory"
  exit 1
fi
TmpFile=`pwd`/filelist.tmp
VersionFound="n/a"
Finish=false
for Thing in $@; do
  find $Dir -name $Thing -type d -print >$TmpFile
  exec <$TmpFile
  while read -r DirToCheck; do
    cd $DirToCheck
    for File in *; do
      if test -d $File; then
        if test "$VersionFound" = "n/a"; then
          VersionFound=$File
          Finish=true
        else
          VersionFound="n/a"
          Finish=false
          break
        fi
      fi
    done
    if $Finish; then
      break
    fi
  done
  if $Finish; then
    break
  fi
done
rm -f $TmpFile
if $Finish; then
  echo $VersionFound
else
  echo "None of the supplied components were found."
  exit 1
fi
