#!/bin/sh

GIT_VERSION=`git --version | awk '{print $3}'`
URL="https://raw.github.com/git/git/v$GIT_VERSION/contrib/completion/git-completion.bash"


PROFILE="$HOME/.bashrc"
echo "Downloading git-completion for git version: $GIT_VERSION..."
if ! curl "$URL" --silent --output "$HOME/.git-completion.bash"; then
	echo "ERROR: Couldn't download completion script. Make sure you have a working internet connection." && exit 1
fi

SOURCE_LINE="source ~/.git-completion.bash"


if [[ -f "$PROFILE" ]] && grep -q "$SOURCE_LINE" "$PROFILE"; then
	echo "Already added to bash profile."
else
	echo "Adding to bash profile..."
	echo "$SOURCE_LINE" >> "$PROFILE"
fi

echo "Reloading bash profile..."
. "$PROFILE"
echo
echo "Successfully installed."
echo "Git auto-completion should be all set!"
