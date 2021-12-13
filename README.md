# Useful shell commands

## Push branch to GitHub: create or update PR
```
git push -u origin "$(git branch --show-current)"

# force (after rebase, deleted commit, etc.)
git push -u origin +"$(git branch --show-current)"
```

## Append newlines to files in PR (only if missing)
```
# https://stackoverflow.com/a/16198793 + https://unix.stackexchange.com/a/9499 to process spaces in file names
OIFS="$IFS"
IFS=$'\n'
for file in $(git --no-pager diff --name-only origin/HEAD $(git branch --show-current)); do
  if [[ $(tail -c1 "$file") && -f "$file" ]]; then
    echo '' >> "$file"
    echo "Appended newline to '$file'"
  fi
done
IFS="$OIFS"
```
