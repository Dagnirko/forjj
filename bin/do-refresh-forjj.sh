#!/usr/bin/env bash

if [[ "$1" != "" ]]
then
    VERSION="$1"
else
    VERSION="latest"
fi

DIFF=$(which colordiff 2>/dev/null)
if [[ "$DIFF" = "" ]]
then
   DIFF=$(which diff 2>/dev/null)
fi

DOWNLOAD_PROG="$(which wget)"
DOWNLOAD_PROG_ARGS=" -q -O "
if [[ "$DOWNLOAD_PROG" = "" ]]
then
    DOWNLOAD_PROG="$(which curl)"
    DOWNLOAD_PROG_ARGS=" -s -o "
fi

if [[ "$DOWNLOAD_PROG" = "" ]]
then    
    echo "Unable to refresh forjj. Missing wget or curl. Please install one of them and retry."
    exit 1
fi

set -e
mkdir -p ~/bin
cd ~/bin

set +e
echo "Refreshing do-refresh-forjj.sh..."
$DOWNLOAD_PROG $DOWNLOAD_PROG_ARGS ~/bin/do-refresh-forjj.new https://github.com/forj-oss/forjj/raw/master/bin/do-refresh-forjj.sh
DO_REFRESH_STATUS=$?
if [[ "$1" = "--restore" ]]
then
    if [[ ! -f forjj.backup ]]
    then 
        echo "No forjj backup to restore."
    else
        mv ~/bin/forjj.backup ~/bin/forjj
        ~/bin/forjj --version
        echo "Previous forjj version restored."
    fi
    exit
fi

echo "Downloading forjj..."
$DOWNLOAD_PROG $DOWNLOAD_PROG_ARGS ~/bin/forjj.new https://github.com/forj-oss/forjj/releases/download/$VERSION/forjj
set -e
if [[ -f ~/bin/forjj ]] 
then
    chmod +x ~/bin/forjj.new
    OLD_FORJJ="$(~/bin/forjj --version 2>/dev/null)"
    NEW_FORJJ="$(~/bin/forjj.new --version 2>/dev/null)"
    if [[ "$OLD_FORJJ" != "$NEW_FORJJ" ]]
    then
        if [[ "$DIFF" != "" ]]
        then
            set +e
            $DIFF --side-by-side <(~/bin/forjj --version 2>/dev/null| sed 's/, /\n/g') <(~/bin/forjj.new --version | sed 's/, /\n/g')
            set -e
        else
            echo "Forjj has been updated:"
            echo "OLD: $OLD_FORJJ"
            echo "NEW: $NEW_FORJJ"
        fi
        mv forjj forjj.backup
        mv forjj.new forjj
    else
        echo "You already have the $VERSION version."
        rm -f ~/bin/forjj.new
    fi

    printf "\nTo restore the previous version, use $0 --restore.\n"

else
   mv ~/bin/forjj.new ~/bin/forjj 
   echo "Welcome to Forjj! Thank you for choosing and testing forjj. 
If you found issues, create issue in https://github.com/forjj-oss/forjj/issues/new

You can reach us also irc.freenode.net#forj"
fi
chmod +x ~/bin/forjj

if [[ $DO_REFRESH_STATUS -eq 0 ]] 
then
    if [[ -f ~/bin/do-refresh-forjj.new ]] 
    then
        chmod +x ~/bin/do-refresh-forjj.new
        mv ~/bin/do-refresh-forjj.new ~/bin/do-refresh-forjj.sh
    fi
else
    rm -f ~/bin/do-refresh-forjj.new
    echo "Unable to refresh the refresher script... wget https://github.com/forj-oss/forjj/raw/master/bin/do-refresh-forjj.sh fails."
fi
