#!/usr/bin/env bash
# Fetch UNRESOLVED review threads for a PR as a JSON array, newest-first.
#
# Usage:
#   fetch-threads.sh [PR_NUMBER]
#     PR_NUMBER  optional; defaults to the PR for the current branch.
#
# Output (stdout): JSON array. Each element:
#   {
#     threadId, path, line, isOutdated,
#     rootCommentId,        # databaseId of the first comment -> reply target
#     lastAuthor, lastAt,   # newest comment in the thread (sort key)
#     diffHunk,             # code context from the root comment
#     comments: [ {author, at, body} ... ]   # full chain, oldest-first
#   }
#
# Threads are sorted by `lastAt` descending (most recently active first),
# matching the "fetch starting from the last" requirement.
#
# Requires: gh, jq. Resolution state lives only on GraphQL reviewThreads,
# which is why this cannot be done via the REST /pulls/{n}/comments endpoint.
set -euo pipefail

PR="${1:-}"
if [[ -z "$PR" ]]; then
  PR="$(gh pr view --json number -q .number)"
fi
read -r OWNER REPO < <(gh repo view --json owner,name -q '.owner.login + " " + .name')

cursor=""
nodes_file="$(mktemp)"
trap 'rm -f "$nodes_file"' EXIT
echo "[]" > "$nodes_file"

while :; do
  resp="$(gh api graphql -f query='
    query($owner:String!,$repo:String!,$pr:Int!,$cursor:String){
      repository(owner:$owner,name:$repo){
        pullRequest(number:$pr){
          reviewThreads(first:100, after:$cursor){
            pageInfo{ hasNextPage endCursor }
            nodes{
              id isResolved isOutdated path line
              comments(first:50){
                nodes{ databaseId author{login} createdAt body diffHunk }
              }
            }
          }
        }
      }
    }' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR" \
       ${cursor:+-F cursor="$cursor"})"

  page="$(echo "$resp" | jq '[
    .data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved == false)
    | {
        threadId: .id,
        path: .path,
        line: .line,
        isOutdated: .isOutdated,
        rootCommentId: (.comments.nodes[0].databaseId // null),
        diffHunk: (.comments.nodes[0].diffHunk // ""),
        lastAuthor: (.comments.nodes[-1].author.login // "unknown"),
        lastAt: (.comments.nodes[-1].createdAt // ""),
        comments: [ .comments.nodes[] | {author: (.author.login // "unknown"), at: .createdAt, body: .body} ]
      }
  ]')"

  jq -s '.[0] + .[1]' "$nodes_file" <(echo "$page") > "$nodes_file.tmp"
  mv "$nodes_file.tmp" "$nodes_file"

  has_next="$(echo "$resp" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')"
  cursor="$(echo "$resp" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')"
  [[ "$has_next" == "true" ]] || break
done

jq 'sort_by(.lastAt) | reverse' "$nodes_file"
