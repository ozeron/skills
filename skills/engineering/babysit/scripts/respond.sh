#!/usr/bin/env bash
# Reply to a review thread and (optionally) resolve it, in one step.
#
# Usage:
#   respond.sh <PR_NUMBER> <ROOT_COMMENT_ID> <THREAD_ID> <RESOLVE> <BODY>
#     ROOT_COMMENT_ID  databaseId of the thread's first comment (reply target)
#     THREAD_ID        GraphQL node id of the thread (for resolution)
#     RESOLVE          "resolve" to resolve after replying; anything else to skip
#     BODY             reply text (use $'...' for multi-line)
#
# Posts the reply via REST (threaded), then resolves via GraphQL mutation.
# Resolving a thread is only possible through GraphQL resolveReviewThread.
set -euo pipefail

PR="$1"; ROOT="$2"; THREAD="$3"; RESOLVE="$4"; BODY="$5"
read -r OWNER REPO < <(gh repo view --json owner,name -q '.owner.login + " " + .name')

gh api -X POST "repos/$OWNER/$REPO/pulls/$PR/comments/$ROOT/replies" \
  -f body="$BODY" --jq '{replied: .id, url: .html_url}'

if [[ "$RESOLVE" == "resolve" ]]; then
  gh api graphql -f query='
    mutation($id:ID!){
      resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } }
    }' -F id="$THREAD" --jq '{resolved: .data.resolveReviewThread.thread.isResolved}'
fi
