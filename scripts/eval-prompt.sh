#!/usr/bin/env bash
# Run prompts/sharpen.md against OpenRouter for a fixed list of lazy inputs.
# Reads the OpenRouter key from Sharpie's keychain entry (write one via
# Settings… first if you haven't). Override the model with MODEL=… in env.

set -euo pipefail

cd "$(dirname "$0")/.."

KEY=$(security find-generic-password \
    -s "ai.sharpie.app" \
    -a "openrouter.api_key" \
    -w 2>/dev/null) || {
    echo "Couldn't read the OpenRouter key from Keychain." >&2
    echo "Open Sharpie → Settings… → save a key, then re-run." >&2
    exit 1
}

MODEL=${MODEL:-anthropic/claude-sonnet-4.5}
PROMPT_PATH="prompts/sharpen.md"
[ -f "$PROMPT_PATH" ] || { echo "Missing $PROMPT_PATH" >&2; exit 1; }

INPUTS=(
    "fix the login bug"
    "write tests for the api"
    "this is slow"
    "refactor user.ts to use async/await"
    "why is the build failing on CI"
    "add error handling to the upload flow"
    "explain this"
    "add a submit button to the contact form"
    "there's a memory leak somewhere in the worker"
    "add caching to the user query"
    "add a new endpoint for /users/me"
    "handle the edge case where the array is empty"
    "do the thing we talked about"
    "make it work like the mockup"
    "Look at this error: TypeError: Cannot read property 'id' of undefined"
)

echo "model: $MODEL"
echo "prompt: $PROMPT_PATH ($(wc -c < "$PROMPT_PATH" | tr -d ' ') bytes)"
echo

for INPUT in "${INPUTS[@]}"; do
    BODY=$(jq -n \
        --arg model "$MODEL" \
        --rawfile system "$PROMPT_PATH" \
        --arg user "$INPUT" \
        '{
            model: $model,
            max_tokens: 1024,
            messages: [
                {role: "system", content: $system},
                {role: "user",   content: $user}
            ]
        }')

    RAW=$(curl -s --max-time 30 https://openrouter.ai/api/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $KEY" \
        -H "HTTP-Referer: https://github.com/vikranthreddimasu/sharpie" \
        -H "X-Title: Sharpie eval" \
        -d "$BODY")

    OUT=$(echo "$RAW" | jq -r '
        .choices[0].message.content
        // .error.message
        // ("<unparseable: " + (.|tostring) + ">")
    ')

    echo "════════════════════════════════════════"
    echo "IN:  $INPUT"
    echo "OUT: $OUT"
    echo
done
