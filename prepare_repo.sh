#!/usr/bin/env bash

# This script prepares the repository for dev

TARGET_VCS="github" # or "gitlab" or "gitea"

GITHUB_API_TOKEN="${GITHUB_API_TOKEN:-}"
GITLAB_API_TOKEN="${GITLAB_API_TOKEN:-}"

function download_file() {
    local repo_name="$1"
    local file_source="$2"
    local output_path="$3"

    local file_url="https://raw.githubusercontent.com/${repo_name}/HEAD/${file_source}"

    # In case we want to switch to gitlab/gitea, here are the urls :
    # GitLab: https://gitlab.com/bgiarrizzo/dxp_tools/-/raw/HEAD/precommit/config.yaml
    # Gitea: https://${INSTANCE_URL}/bgiarrizzo/dxp_tools/raw/HEAD/precommit/config.yaml

    # Check if the file exists in the repository before attempting to download it
    # If file exists, create output directory if it doesn't exist and download the file
    if [[ -n "${GITHUB_API_TOKEN}" ]]; then
        # Check if file exists in GitHub repository
        local api_url="https://api.github.com/repos/${repo_name}/contents/${file_source}"
        curl -H "Authorization: token ${GITHUB_API_TOKEN}" -f -L "${api_url}" > /dev/null 2>&1

        if [[ $? -ne 0 ]]; then
            echo "Warning: File ${file_source} not found in repository ${repo_name}. Skipping download."
            return
        else
            mkdir -p "$(dirname "${output_path}")"
        fi
    else
        echo "Error: GITHUB_API_TOKEN is not set. Cannot check for file existence."
        exit 1
    fi


    echo "Download : ${file_source} -> ${output_path} ..."

    curl \
        -H "Authorization: token ${GITHUB_API_TOKEN}" \
        -f -L -o "${output_path}" "${file_url}" \
        > /dev/null 2>&1

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to download file from ${file_url}"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Main Script Execution
# -----------------------------------------------------------------------------

# Create folders

mkdir -p src
mkdir -p docs/ADR
mkdir -p docker

if [[ ${TARGET_VCS} == "github" ]]; then
    mkdir -p .github/workflows
fi

REPO_NAME="bgiarrizzo/dxp_tools"

# -----------------------------------------------------------------------------
# Download mandatory files
# -----------------------------------------------------------------------------

# Pre-Commit config
download_file ${REPO_NAME} "precommit/config.yaml" ".pre-commit-config.yaml"
# Git ignore
download_file ${REPO_NAME} "git/gitignore" ".gitignore"
# Docker ignore
download_file ${REPO_NAME} "docker/dockerignore" ".dockerignore"
# EditorConfig
download_file ${REPO_NAME} "config/editorconfig" ".editorconfig"

# -----------------------------------------------------------------------------
# Optional files
# -----------------------------------------------------------------------------

# # AI Agent documentation
download_file ${REPO_NAME} "agents/swift/vapor.md" "AGENTS.md"
download_file ${REPO_NAME} "agents/swift/docs/README.md" "docs/README.md"
download_file ${REPO_NAME} "agents/swift/docs/ADR/0000-adr-index.md" "docs/ADR/0000-adr-index.md"
download_file ${REPO_NAME} "agents/swift/docs/ADR/0001-adr-template.md" "docs/ADR/0001-adr-template.md"

# # Mise Configuration
download_file ${REPO_NAME} "config/mise/mise.toml" "mise.toml"

# # Swift Format configuration
# download_file ${REPO_NAME} "config/swift/swiftformat.json" ".swiftformat.json"

# # Yaml Linting configuration
# download_file ${REPO_NAME} "config/yamllint.yaml" ".yamllint.yaml"

# # Markdown
