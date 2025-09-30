#!/bin/bash

# ClaudeCode Settings Generator
# Generates proper settings.json for ClaudeCode hooks integration

set -euo pipefail

# Get the absolute path to the hook script
HOOK_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/update_status.sh"

# Verify hook script exists
if [[ ! -f "$HOOK_SCRIPT_PATH" ]]; then
    echo "Error: Hook script not found at $HOOK_SCRIPT_PATH" >&2
    exit 1
fi

# Generate the hooks configuration
generate_hooks_config() {
    cat << EOF
{
    "hooks": {
        "UserPromptSubmit": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$HOOK_SCRIPT_PATH processing"
                    }
                ]
            }
        ],
        "Notification": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$HOOK_SCRIPT_PATH attention"
                    }
                ]
            }
        ],
        "Stop": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$HOOK_SCRIPT_PATH completed"
                    }
                ]
            }
        ],
        "SessionStart": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$HOOK_SCRIPT_PATH connected"
                    }
                ]
            }
        ],
        "SessionEnd": [
            {
                "matcher": "",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$HOOK_SCRIPT_PATH disconnected"
                    }
                ]
            }
        ]
    }
}
EOF
}

# Merge with existing configuration
merge_with_existing() {
    local existing_config="$1"
    local new_hooks_config="$2"
    local merge_mode="${3:-preserve}"  # preserve, replace, or append

    # Check if existing config has hooks
    if echo "$existing_config" | jq -e '.hooks' > /dev/null 2>&1; then
        echo "Merging with existing hooks configuration (mode: $merge_mode)..." >&2

        # For each hook type, check if it already exists
        local hook_types=("UserPromptSubmit" "Notification" "Stop" "SessionStart" "SessionEnd")

        for hook_type in "${hook_types[@]}"; do
            if echo "$existing_config" | jq -e ".hooks.\"$hook_type\"" > /dev/null 2>&1; then
                case "$merge_mode" in
                    "preserve")
                        echo "Preserving existing hook '$hook_type'" >&2
                        ;;
                    "replace")
                        echo "Replacing existing hook '$hook_type' with monitor hook" >&2
                        existing_config=$(echo "$existing_config" | jq \
                            --argjson hook_config "$(echo "$new_hooks_config" | jq ".hooks.\"$hook_type\"")" \
                            ".hooks.\"$hook_type\" = \$hook_config")
                        ;;
                    "append")
                        echo "Appending monitor hook to existing '$hook_type'" >&2
                        # Add our hook to the existing hooks array
                        local our_hook
                        our_hook=$(echo "$new_hooks_config" | jq ".hooks.\"$hook_type\"[0]")
                        existing_config=$(echo "$existing_config" | jq \
                            --argjson new_hook "$our_hook" \
                            ".hooks.\"$hook_type\" += [\$new_hook]")
                        ;;
                esac
            else
                # Hook doesn't exist, add it regardless of mode
                echo "Adding new hook '$hook_type'" >&2
                existing_config=$(echo "$existing_config" | jq \
                    --argjson hook_config "$(echo "$new_hooks_config" | jq ".hooks.\"$hook_type\"")" \
                    ".hooks.\"$hook_type\" = \$hook_config")
            fi
        done

        echo "$existing_config"
    else
        # No existing hooks, merge the entire hooks section
        echo "$existing_config" | jq \
            --argjson hooks "$(echo "$new_hooks_config" | jq '.hooks')" \
            '. + {"hooks": $hooks}'
    fi
}

# Main execution
case "${1:-generate}" in
    "generate")
        generate_hooks_config
        ;;
    "merge")
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 merge <existing_config_file> [merge_mode]" >&2
            echo "  merge_mode: preserve (default), replace, or append" >&2
            exit 1
        fi

        existing_file="$2"
        merge_mode="${3:-preserve}"

        if [[ ! -f "$existing_file" ]]; then
            echo "Error: Existing config file '$existing_file' not found" >&2
            exit 1
        fi

        if [[ ! "$merge_mode" =~ ^(preserve|replace|append)$ ]]; then
            echo "Error: Invalid merge mode '$merge_mode'. Use: preserve, replace, or append" >&2
            exit 1
        fi

        existing_config=$(cat "$existing_file")
        new_hooks_config=$(generate_hooks_config)

        merge_with_existing "$existing_config" "$new_hooks_config" "$merge_mode"
        ;;
    *)
        echo "Usage: $0 {generate|merge} [existing_config_file] [merge_mode]" >&2
        echo "  generate                    - Generate new hooks configuration" >&2
        echo "  merge <config> [mode]       - Merge with existing configuration" >&2
        echo "    mode: preserve (keep existing), replace (override), append (chain)" >&2
        exit 1
        ;;
esac