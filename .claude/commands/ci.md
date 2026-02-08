Check the status of the latest CI run.

Steps:
1. Run `gh run list --limit 3` to show recent runs
2. If the most recent run is in progress, watch it with `gh run watch <id> --exit-status`
3. If it completed, show the final status (success/failure)
4. If it failed, show the failed step and relevant log output using `gh run view <id> --log-failed`
