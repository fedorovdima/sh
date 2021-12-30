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

## Clean up branches from old merged PRs on GitHub
```
# Show branches from old merged PRs (colored output)
git branch --sort=committerdate --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' --no-merged

# Burn them all!
git branch --no-merged | xargs git branch -D
```

## Working with GCP Secret Manager
```
# Put secret(s) to GCP SM
IFS=,; while read key value; do printf "%s" "$value" | tr -d '\r' | gcloud secrets --project=${PROJECT_NAME} versions add "$key" --data-file=-; done < /tmp/pwds.csv
```
