Release a new version of MermaidViewer. The version number is provided as $ARGUMENTS (e.g. "1.3.0").

Steps:
1. Verify the working tree is clean (error if uncommitted changes)
2. Update `MARKETING_VERSION` in `project.yml` to the provided version
3. Commit: `chore: Bump version to <version>`
4. Push to main
5. Create git tag `v<version>` and push it (this triggers the CI release workflow)
6. Watch the CI run with `gh run watch` until completion
7. Verify the Homebrew cask at `johnoscott/homebrew-mermaid-viewer` was updated to the new version
8. Report the final status: GitHub Release URL, Homebrew cask version, and SHA256
