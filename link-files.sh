#!/bin/bash
FILES_HOME=(".tmux.conf" ".zshrc")
FILES_HOME_DEST="$HOME"
LISTS=("FILES_HOME")

# This script iterates through all given lists above and creates symbolic links for the specified files
# in their respective source destination. Behaviour:
# When you want to skip creation of symbolic links for existing files:
#   If destination file does exist:
#     No backup of the original file is made, no link is made
#   If destination file does not exist:
#     Link is made
# When you don't want to skip creation of symbolic links for existing files:
#   If destination file does exist:
#     Backup of the original file is made, link is made
#   If destination file does not exist:
#     Link is made
# In all cases, when a symbolic link (it doesn't matter where it links to) already exists in the destination:
#   No link is made, no backup is made

link_files () {
  local DEST="$1"
  # Shift all arguments to the left (original $1 gets lost)
  shift
  local FILES=("$@")
  for FILE in "${FILES[@]}"; do
    local FILE_EXISTS="false"
    local LINK_EXISTS="false"
    if [[ -f "$DEST/$FILE" ]]; then
      if [[ -h "$DEST/$FILE" ]]; then
        local LINK_EXISTS="true"
      else
        local FILE_EXISTS="true"
      fi
    else
      # File and link do not exist on destination
    fi

    if [[ $FILE_EXISTS == "true" ]]; then
      if [[ $SKIP_EXISTING_FILES == "false" ]]; then
        echo "File '$DEST/$FILE' does already exist. Backing up"
        mv "$DEST/$FILE" "$DEST/$FILE.bak"
      else
        echo "File '$DEST/$FILE' does already exist. Skipping"
      fi
    fi

    if ! ([[ $SKIP_EXISTING_FILES == "true" ]] && [[ $FILE_EXISTS == "true" ]]); then
      if [[ $LINK_EXISTS == "false" ]]; then
        echo "Linking file '$PWD/$FILE' to '$DEST/$FILE'"
        ln -s "$PWD/$FILE" "$DEST/$FILE"
      else
        echo "A link already exists in destination. Skipping file '$PWD/$FILE' with destination '$DEST/$FILE'"
      fi
    fi
  done
}

echo 'The following files will be linked:'
for LIST in ${LISTS[@]}; do
  FILES_VAR=$LIST[*]
  DEST_VAR=${LIST}_DEST
  echo "'${!FILES_VAR}' with destination '${!DEST_VAR}'"
done

echo ''
echo 'Do you want to skip creation of symbolic links for files which already exist? [y/n]'

read INPUT
if [[ $INPUT == "y" ]]; then
  SKIP_EXISTING_FILES="true"
  echo 'Skipping existing files'
else
  SKIP_EXISTING_FILES="false"
  echo 'Not skipping existing files'
fi

echo ''
echo 'Do you want to continue? [y/n]'

read INPUT
if [[ $INPUT != "y" ]]; then
  echo 'Nothing happened. Exiting script'
  exit
fi

for LIST in ${LISTS[@]}; do
  # variable indirection, see bash man "parameter expansion"
  FILES_VAR=$LIST[@]
  DEST_VAR=${LIST}_DEST
  link_files ${!DEST_VAR} ${!FILES_VAR} 
done

echo 'Script finished'
