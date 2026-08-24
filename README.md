# Claude Code settings backup

Only non-secret, non-history config tracked (see .gitignore for whitelist):

- settings.json
- statusline-command.sh
- plugins/known_marketplaces.json, plugins/installed_plugins.json

Everything else in this dir (.credentials.json, history.jsonl, sessions/, projects/, cache/) is ignored on purpose.

## After cloning onto a new machine

The statusline (`statusline-command.sh`) works out of the box, but the email line
(line 3) needs a local, untracked file since email is not committed here:

```sh
echo "you@example.com" > ~/.claude/account-email.txt
```

If that file is missing, the statusline just omits the email line — nothing breaks.
