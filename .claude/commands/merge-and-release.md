Merge the current open PR and release a new version. The version number is provided as $ARGUMENTS (e.g. "1.3.0").

Steps:
1. Find the open PR for the current branch using `gh pr list`
2. Merge it with `gh pr merge <number> --merge`
3. Switch to main and pull
4. Update `MARKETING_VERSION` in `project.yml` to the provided version
5. Commit: `chore: Bump version to <version>`
6. Push to main
7. Create git tag `v<version>` and push it (this triggers the CI release workflow)
8. Watch the CI run with `gh run watch` until completion
9. Verify the Homebrew cask at `johnoscott/homebrew-mermaid-viewer` was updated to the new version
10. Report the final status: PR merge, GitHub Release URL, Homebrew cask version
