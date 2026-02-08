Verify the current state of the Homebrew cask for MermaidViewer.

Steps:
1. Fetch the current cask formula from `johnoscott/homebrew-mermaid-viewer` using `gh api repos/johnoscott/homebrew-mermaid-viewer/contents/Casks/mermaid-viewer.rb --jq '.content' | base64 -d`
2. Show the current version and SHA256
3. Compare with the latest GitHub release version using `gh release view --json tagName`
4. Report whether the cask is up to date or out of sync
5. Show the `brew upgrade --cask mermaid-viewer` command the user can run to test locally
