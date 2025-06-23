# bootstrap_token.sh — initialise PAT & owner for profile-README updater
# Usage: source bootstrap_token.sh
# Requires: GitHub CLI (`gh`), curl, jq

bootstrap_github_token() {
    # set -euo pipefail   # Removed to avoid affecting interactive shell

    REPO_OWNER_DEFAULT=$(gh auth status --show-token 2>/dev/null | awk '/Logged in to github.com as/ {print $6}')
    printf "GitHub owner/user [%s]: " "${REPO_OWNER_DEFAULT}"
    read -r OWNER
    OWNER=${OWNER:-$REPO_OWNER_DEFAULT}

    printf "Paste fine-grained PAT (read-only, profile repo): "
    read -rs PAT
    echo
    [[ -z "$PAT" ]] && { echo "✖ Token empty — aborting"; return 1; }

    echo "➟ Verifying token…"
    resp=$(curl -sf \
      -H "Authorization: bearer $PAT" \
      -H "Content-Type: application/json" \
      -d '{"query":"query{viewer{login}}"}' \
      https://api.github.com/graphql) || { echo "✖ API call failed — token invalid?"; return 1; }

    login=$(echo "$resp" | jq -r .data.viewer.login)
    if [[ "$login" != "$OWNER" ]]; then
      echo "✖ Token belongs to '$login', but owner set to '$OWNER'."
      printf "Continue anyway? [y/N] "
      read -r ans
      [[ "$ans" =~ ^[Yy]$ ]] || return 1
    fi
    echo "✓ Token valid."

    # Export environment variables for immediate use
    export GH_OWNER="$OWNER"
    export GH_TOKEN="$PAT"
    echo "✓ Environment variables exported: GH_OWNER=$OWNER, GH_TOKEN=***"

    # Save to GitHub secret (optional)
    echo "➟ Uploading secret to repo '$OWNER/$OWNER' …"
    if gh secret set GH_OVERVIEW_TOKEN --body "$PAT" --repo "$OWNER/$OWNER"; then
      echo "✓ Secret GH_OVERVIEW_TOKEN created/updated."
    else
      echo "✖ Could not set secret with gh CLI — do you have permission?"
      echo "   Manually run:  gh secret set GH_OVERVIEW_TOKEN --body <token> --repo $OWNER/$OWNER"
    fi

    cat <<EOF

Done ✔

Environment variables are now set for this shell session.
You can now run: python3 scripts/generate-overview.py

Note: Environment variables will be lost when you close this terminal.
For CI/CD, use the GitHub secret: \${{ secrets.GH_OVERVIEW_TOKEN }}

Token rotation: re-run this script to update the secret and environment variables.
EOF
}

# Auto-run the function when sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    echo "This script should be sourced, not executed directly."
    echo "Usage: source bootstrap_token.sh"
    exit 1
else
    # Script is being sourced
    bootstrap_github_token
fi

