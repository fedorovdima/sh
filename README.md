# For useful shell commands

## Append newlines to files in PR (only if missing)
```
for file in $(git --no-pager diff --name-only origin/HEAD $(git branch --show-current)); do echo "file: $file"; [[ $(tail -c1 $file) && -f $file ]] && echo '' >> $file; done
```
