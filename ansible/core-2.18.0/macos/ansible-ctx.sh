# Ansible context switcher
ansible-ctx() {
    local global_contexts_dir="$HOME/.ansible/contexts"
    local current_file="$global_contexts_dir/current"

    # Color scheme
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local NC='\033[0m' # No Color

    mkdir -p "$global_contexts_dir"

    # Function to determine project root
    _find_project_root() {
        local current_dir="$(pwd)"
        local search_dir="$current_dir"

        # Look for git repository, ansible.cfg or inventories folder
        while [ "$search_dir" != "/" ]; do
            if [ -d "$search_dir/.git" ] || [ -f "$search_dir/ansible.cfg" ] || [ -d "$search_dir/inventories" ]; then
                echo "$search_dir"
                return 0
            fi
            search_dir="$(dirname "$search_dir")"
        done

        # If not found, use current directory
        echo "$current_dir"
    }

    # Function to get project name
    _get_project_name() {
        local project_root="$1"
        basename "$project_root"
    }

    # Function to get current active context for project
    _get_current_context() {
        local project_root="$1"

        if [ -f "$current_file" ]; then
            local current_info=$(cat "$current_file")
            local current_project=$(echo "$current_info" | cut -d: -f1)
            local current_ctx=$(echo "$current_info" | cut -d: -f2)

            if [ "$current_project" = "$project_root" ]; then
                echo "$current_ctx"
                return 0
            fi
        fi

        return 1
    }

    # Function to scan folders in inventories/
    _scan_inventory_contexts() {
        local project_root="$1"
        local inventories_dir="$project_root/inventories"
        local found_contexts=()

        # Check if inventories folder exists
        if [ ! -d "$inventories_dir" ]; then
            return 0
        fi

        # Scan folders in inventories/
        for item in "$inventories_dir"/*; do
            if [ -d "$item" ]; then
                local context_name=$(basename "$item")
                # Check that folder has at least one file (not empty)
                if [ "$(ls -A "$item" 2>/dev/null)" ]; then
                    found_contexts+=("$context_name")
                fi
            elif [ -f "$item" ]; then
                # Also include individual files in inventories/ as contexts
                local context_name=$(basename "$item" | sed 's/\.[^.]*$//')
                found_contexts+=("$context_name")
            fi
        done

        # Remove duplicates and sort
        printf '%s\n' "${found_contexts[@]}" | sort -u
    }

    # Function to get inventory path for context
    _get_inventory_path() {
        local project_root="$1"
        local context_name="$2"
        local inventories_dir="$project_root/inventories"

        # First check folder
        if [ -d "$inventories_dir/$context_name" ]; then
            echo "$inventories_dir/$context_name/"
            return 0
        fi

        # Then look for files with extensions
        local extensions=("" ".yml" ".yaml" ".ini" ".inv")
        for ext in "${extensions[@]}"; do
            if [ -f "$inventories_dir/$context_name$ext" ]; then
                echo "$inventories_dir/$context_name$ext"
                return 0
            fi
        done

        return 1
    }

    local project_root=$(_find_project_root)
    local project_name=$(_get_project_name "$project_root")
    local contexts_dir="$project_root/.ansible-contexts"
    local inventories_dir="$project_root/inventories"

    case "$1" in
        "")
            if [ -f "$current_file" ]; then
                local current_info=$(cat "$current_file")
                local current_project=$(echo "$current_info" | cut -d: -f1)
                local current_ctx=$(echo "$current_info" | cut -d: -f2)

                if [ "$current_project" = "$project_root" ] && [ -f "$contexts_dir/$current_ctx" ]; then
                    local inventory_path=$(cat "$contexts_dir/$current_ctx")
                    echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC} (${YELLOW}$project_root${NC})"
                    echo -e "${BOLD}Current:${NC} ${BLUE}$current_ctx${NC} -> ${YELLOW}$inventory_path${NC}"
                else
                    echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC} (${YELLOW}$project_root${NC})"
                    if [ "$current_project" != "$project_root" ]; then
                        echo -e "${YELLOW}No context set for this project${NC}"
                        if [ -n "$current_project" ]; then
                            echo -e "${YELLOW}Global context is set for: $current_project${NC}"
                        fi
                    else
                        echo -e "${RED}Current context '$current_ctx' is broken${NC}"
                    fi
                fi
            else
                echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC} (${YELLOW}$project_root${NC})"
                echo -e "${YELLOW}No context set${NC}"
            fi

            # Show inventories folder status
            if [ -d "$inventories_dir" ]; then
                local inventory_count=$(find "$inventories_dir" -maxdepth 1 -type d ! -path "$inventories_dir" | wc -l)
                local file_count=$(find "$inventories_dir" -maxdepth 1 -type f | wc -l)
                echo -e "${CYAN}Inventories:${NC} ${inventory_count} folders, ${file_count} files"
            else
                echo -e "${YELLOW}No inventories/ directory found${NC}"
            fi
            ;;
        "list")
            echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC} (${YELLOW}$project_root${NC})"

            # Get current active context
            local current_ctx=""
            current_ctx=$(_get_current_context "$project_root")

            echo -e "${BOLD}Available contexts:${NC}"
            if [ -d "$contexts_dir" ]; then
                local found_contexts=false
                for ctx_file in "$contexts_dir"/*; do
                    if [ -f "$ctx_file" ]; then
                        local ctx_name=$(basename "$ctx_file")
                        local inventory_path=$(cat "$ctx_file")
                        local is_current=false

                        # Check if this context is current
                        if [ "$ctx_name" = "$current_ctx" ]; then
                            is_current=true
                        fi

                        # Format output based on status
                        if [ -e "$inventory_path" ]; then
                            if [ "$is_current" = true ]; then
                                # Current active context - green with arrow and bold
                                echo -e "  ${BOLD}${GREEN}► $ctx_name${NC} -> ${BOLD}${YELLOW}$inventory_path${NC} ${BOLD}${GREEN}(active)${NC}"
                            else
                                # Regular available context
                                echo -e "    ${GREEN}$ctx_name${NC} -> ${YELLOW}$inventory_path${NC}"
                            fi
                        else
                            if [ "$is_current" = true ]; then
                                # Current context with issues
                                echo -e "  ${BOLD}${RED}► $ctx_name${NC} -> ${RED}$inventory_path${NC} ${RED}(not found, active)${NC}"
                            else
                                # Broken context
                                echo -e "    ${RED}$ctx_name${NC} -> ${RED}$inventory_path${NC} ${RED}(not found)${NC}"
                            fi
                        fi
                        found_contexts=true
                    fi
                done
                if [ "$found_contexts" = false ]; then
                    echo -e "  ${YELLOW}No contexts found in this project${NC}"
                fi
            else
                echo -e "  ${YELLOW}No contexts directory found${NC}"
            fi

            # Show available in inventories/ if they're not added as contexts
            if [ -d "$inventories_dir" ]; then
                local available_contexts=()
                while IFS= read -r line; do
                    [ -n "$line" ] && available_contexts+=("$line")
                done < <(_scan_inventory_contexts "$project_root")

                local not_added_contexts=()
                for available_ctx in "${available_contexts[@]}"; do
                    if [ ! -f "$contexts_dir/$available_ctx" ]; then
                        not_added_contexts+=("$available_ctx")
                    fi
                done

                if [ ${#not_added_contexts[@]} -gt 0 ]; then
                    echo ""
                    echo -e "${BOLD}Available in inventories/ (not added as contexts):${NC}"
                    for ctx in "${not_added_contexts[@]}"; do
                        local inv_path=$(_get_inventory_path "$project_root" "$ctx")
                        if [ -d "$inventories_dir/$ctx" ]; then
                            echo -e "    ${CYAN}$ctx${NC} ${CYAN}(directory)${NC} -> ${YELLOW}${inv_path#$project_root/}${NC}"
                        else
                            echo -e "    ${BLUE}$ctx${NC} ${CYAN}(file)${NC} -> ${YELLOW}${inv_path#$project_root/}${NC}"
                        fi
                    done
                    echo -e "${CYAN}Tip: Use 'ansible-ctx add <name>' to add these as contexts${NC}"
                fi
            fi
            ;;
        "scan")
            echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC} (${YELLOW}$project_root${NC})"
            echo -e "${BOLD}Scanning inventories/ directory...${NC}"

            if [ ! -d "$inventories_dir" ]; then
                echo -e "${RED}No inventories/ directory found${NC}"
                echo -e "${CYAN}Create it with: mkdir inventories${NC}"
                return 1
            fi

            local scanned_contexts=()
            while IFS= read -r line; do
                [ -n "$line" ] && scanned_contexts+=("$line")
            done < <(_scan_inventory_contexts "$project_root")

            if [ ${#scanned_contexts[@]} -gt 0 ]; then
                echo -e "${BOLD}Found inventory contexts:${NC}"
                for context in "${scanned_contexts[@]}"; do
                    local inv_path=$(_get_inventory_path "$project_root" "$context")
                    if [ -d "$inventories_dir/$context" ]; then
                        echo -e "  ${GREEN}$context${NC} ${CYAN}(directory)${NC} -> ${YELLOW}$inv_path${NC}"
                    else
                        echo -e "  ${BLUE}$context${NC} ${CYAN}(file)${NC} -> ${YELLOW}$inv_path${NC}"
                    fi
                done
                echo ""
                echo -e "${CYAN}Use 'ansible-ctx add <name>' to create contexts from these${NC}"
                echo -e "${CYAN}Use 'ansible-ctx import' to import all at once${NC}"
            else
                echo -e "${YELLOW}No inventory contexts found in inventories/${NC}"
                echo -e "${CYAN}Expected structure:${NC}"
                echo -e "  ${YELLOW}inventories/${NC}"
                echo -e "    ${YELLOW}├── prod/${NC}"
                echo -e "    ${YELLOW}├── stage/${NC}"
                echo -e "    ${YELLOW}└── dev/${NC}"
            fi
            ;;
        "import")
            echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC}"
            echo -e "${CYAN}Importing contexts from inventories/...${NC}"

            if [ ! -d "$inventories_dir" ]; then
                echo -e "${RED}No inventories/ directory found${NC}"
                return 1
            fi

            mkdir -p "$contexts_dir"

            local scanned_contexts=()
            local imported_count=0

            while IFS= read -r line; do
                [ -n "$line" ] && scanned_contexts+=("$line")
            done < <(_scan_inventory_contexts "$project_root")

            for context in "${scanned_contexts[@]}"; do
                local inv_path=$(_get_inventory_path "$project_root" "$context")

                # Check that context doesn't exist
                if [ ! -f "$contexts_dir/$context" ]; then
                    echo "$inv_path" > "$contexts_dir/$context"
                    echo -e "  ${GREEN}Added:${NC} ${BLUE}$context${NC} -> ${YELLOW}${inv_path#$project_root/}${NC}"
                    ((imported_count++))
                else
                    echo -e "  ${YELLOW}Skipped:${NC} ${BLUE}$context${NC} -> ${YELLOW}${inv_path#$project_root/}${NC} ${YELLOW}(already exists)${NC}"
                fi
            done

            if [ $imported_count -gt 0 ]; then
                echo -e "${GREEN}Imported $imported_count contexts${NC}"
            else
                echo -e "${YELLOW}No new contexts imported${NC}"
            fi
            ;;
        "use")
            if [ -z "$2" ]; then
                echo -e "${RED}Usage: ansible-ctx use <context-name>${NC}"
                return 1
            fi
            if [ -f "$contexts_dir/$2" ]; then
                local inventory_path=$(cat "$contexts_dir/$2")
                if [ -f "$inventory_path" ] || [ -d "$inventory_path" ]; then
                    export ANSIBLE_INVENTORY="$inventory_path"
                    echo "$project_root:$2" > "$current_file"
                    echo -e "${GREEN}Switched to:${NC} ${BLUE}$2${NC} -> ${YELLOW}$inventory_path${NC}"
                    echo -e "${CYAN}Project:${NC} $project_name"
                else
                    echo -e "${YELLOW}Warning: Inventory path '$inventory_path' does not exist${NC}"
                    export ANSIBLE_INVENTORY="$inventory_path"
                    echo "$project_root:$2" > "$current_file"
                    echo -e "${GREEN}Switched to:${NC} ${BLUE}$2${NC} -> ${RED}$inventory_path${NC} ${YELLOW}(path not found)${NC}"
                fi
            else
                echo -e "${RED}Context '$2' not found in project '$project_name'${NC}"
                echo -e "${CYAN}Try 'ansible-ctx scan' to see available contexts${NC}"
                return 1
            fi
            ;;
        "add")
            if [ -z "$2" ]; then
                echo -e "${RED}Usage: ansible-ctx add <context-name> [inventory-path]${NC}"
                echo -e "${CYAN}If inventory-path is omitted, will look in inventories/<context-name>${NC}"
                return 1
            fi

            mkdir -p "$contexts_dir"

            # Check that context with this name doesn't exist
            if [ -f "$contexts_dir/$2" ]; then
                echo -e "${YELLOW}Context '$2' already exists in project '$project_name'${NC}"
                echo -n "Overwrite? (y/N): "
                read answer
                if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                    return 1
                fi
            fi

            local inventory_path
            if [ -n "$3" ]; then
                # If path is specified explicitly
                inventory_path="$3"
                if [[ ! "$inventory_path" =~ ^/ ]]; then
                    inventory_path="$project_root/$inventory_path"
                fi
            else
                # Try to find in inventories/
                inventory_path=$(_get_inventory_path "$project_root" "$2")
                if [ $? -ne 0 ]; then
                    echo -e "${RED}Context '$2' not found in inventories/${NC}"
                    echo -e "${CYAN}Available contexts:${NC}"
                    while IFS= read -r line; do
                        [ -n "$line" ] && echo -e "  ${YELLOW}$line${NC}"
                    done < <(_scan_inventory_contexts "$project_root")
                    return 1
                fi
            fi

            # Check that inventory exists
            if [ ! -e "$inventory_path" ]; then
                echo -e "${YELLOW}Warning: Path '$inventory_path' does not exist${NC}"
                echo -n "Add anyway? (y/N): "
                read answer
                if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                    return 1
                fi
            else
                # Validate inventory
                if [ -f "$inventory_path" ]; then
                    echo -e "${CYAN}Validating inventory file...${NC}"
                    if command -v ansible-inventory > /dev/null 2>&1; then
                        if ! ansible-inventory -i "$inventory_path" --list > /dev/null 2>&1; then
                            echo -e "${YELLOW}Warning: '$inventory_path' doesn't appear to be a valid inventory file${NC}"
                            echo -n "Add anyway? (y/N): "
                            read answer
                            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                                return 1
                            fi
                        else
                            echo -e "${GREEN}Inventory file validation passed${NC}"
                        fi
                    else
                        echo -e "${YELLOW}ansible-inventory not found, skipping validation${NC}"
                    fi
                elif [ -d "$inventory_path" ]; then
                    echo -e "${CYAN}Directory inventory detected${NC}"
                fi
            fi

            echo "$inventory_path" > "$contexts_dir/$2"
            echo -e "${GREEN}Added context:${NC} ${BLUE}$2${NC} -> ${YELLOW}$inventory_path${NC}"
            echo -e "${CYAN}Project:${NC} $project_name"
            ;;
        "remove"|"rm")
            if [ -z "$2" ]; then
                echo -e "${RED}Usage: ansible-ctx remove <context-name>${NC}"
                return 1
            fi
            if [ -f "$contexts_dir/$2" ]; then
                rm "$contexts_dir/$2"
                echo -e "${GREEN}Removed context:${NC} ${BLUE}$2${NC} ${CYAN}from project ${NC}$project_name"

                # If removing current context, clear current
                if [ -f "$current_file" ]; then
                    local current_info=$(cat "$current_file")
                    local current_project=$(echo "$current_info" | cut -d: -f1)
                    local current_ctx=$(echo "$current_info" | cut -d: -f2)

                    if [ "$current_project" = "$project_root" ] && [ "$current_ctx" = "$2" ]; then
                        rm "$current_file"
                        unset ANSIBLE_INVENTORY
                        echo -e "${YELLOW}Cleared current context${NC}"
                    fi
                fi
            else
                echo -e "${RED}Context '$2' not found in project '$project_name'${NC}"
                return 1
            fi
            ;;
        "edit")
            if [ -z "$2" ]; then
                echo -e "${RED}Usage: ansible-ctx edit <context-name>${NC}"
                return 1
            fi
            if [ -f "$contexts_dir/$2" ]; then
                local current_path=$(cat "$contexts_dir/$2")
                echo -e "${BOLD}Project:${NC} ${CYAN}$project_name${NC}"
                echo -e "${BOLD}Current path for${NC} ${BLUE}$2${NC}: ${YELLOW}$current_path${NC}"
                echo -n "Enter new inventory path: "
                read new_path
                if [ -n "$new_path" ]; then
                    # Convert relative path to absolute
                    local inventory_path="$new_path"
                    if [[ ! "$inventory_path" =~ ^/ ]]; then
                        inventory_path="$project_root/$inventory_path"
                    fi

                    # Validate new path
                    if [ ! -e "$inventory_path" ]; then
                        echo -e "${YELLOW}Warning: Path '$inventory_path' does not exist${NC}"
                        echo -n "Save anyway? (y/N): "
                        read answer
                        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                            return 1
                        fi
                    fi

                    echo "$inventory_path" > "$contexts_dir/$2"
                    echo -e "${GREEN}Updated context:${NC} ${BLUE}$2${NC} -> ${YELLOW}$inventory_path${NC}"

                    # If this is current context, update environment variable
                    if [ -f "$current_file" ]; then
                        local current_info=$(cat "$current_file")
                        local current_project=$(echo "$current_info" | cut -d: -f1)
                        local current_ctx=$(echo "$current_info" | cut -d: -f2)

                        if [ "$current_project" = "$project_root" ] && [ "$current_ctx" = "$2" ]; then
                            export ANSIBLE_INVENTORY="$inventory_path"
                            echo -e "${CYAN}Updated current context environment${NC}"
                        fi
                    fi
                else
                    echo -e "${YELLOW}No changes made${NC}"
                fi
            else
                echo -e "${RED}Context '$2' not found in project '$project_name'${NC}"
                return 1
            fi
            ;;
        "clear")
            if [ -f "$current_file" ]; then
                local current_info=$(cat "$current_file")
                local current_project=$(echo "$current_info" | cut -d: -f1)
                local current_ctx=$(echo "$current_info" | cut -d: -f2)

                if [ "$current_project" = "$project_root" ]; then
                    rm "$current_file"
                    unset ANSIBLE_INVENTORY
                    echo -e "${GREEN}Cleared current context:${NC} ${BLUE}$current_ctx${NC} ${CYAN}in project${NC} $project_name"
                else
                    echo -e "${YELLOW}Current context is not set for this project${NC}"
                fi
            else
                echo -e "${YELLOW}No current context to clear${NC}"
            fi
            ;;
        "status")
            echo -e "${BOLD}Ansible Context Status:${NC}"
            echo -e "  ${BOLD}Project:${NC} ${CYAN}$project_name${NC}"
            echo -e "  ${BOLD}Project Root:${NC} ${YELLOW}$project_root${NC}"
            echo -e "  ${BOLD}Contexts Directory:${NC} ${YELLOW}$contexts_dir${NC}"
            echo -e "  ${BOLD}Inventories Directory:${NC} ${YELLOW}$inventories_dir${NC}"

            if [ -f "$current_file" ]; then
                local current_info=$(cat "$current_file")
                local current_project=$(echo "$current_info" | cut -d: -f1)
                local current_ctx=$(echo "$current_info" | cut -d: -f2)

                if [ "$current_project" = "$project_root" ]; then
                    if [ -f "$contexts_dir/$current_ctx" ]; then
                        local inventory_path=$(cat "$contexts_dir/$current_ctx")
                        echo -e "  ${BOLD}Current Context:${NC} ${BLUE}$current_ctx${NC}"
                        echo -e "  ${BOLD}Inventory Path:${NC} ${YELLOW}$inventory_path${NC}"
                        echo -e "  ${BOLD}ANSIBLE_INVENTORY:${NC} ${CYAN}${ANSIBLE_INVENTORY:-not set}${NC}"

                        # Check inventory availability
                        if [ -e "$inventory_path" ]; then
                            echo -e "  ${BOLD}Status:${NC} ${GREEN}✓ Inventory accessible${NC}"
                        else
                            echo -e "  ${BOLD}Status:${NC} ${RED}✗ Inventory not found${NC}"
                        fi
                    else
                        echo -e "  ${BOLD}Current Context:${NC} ${RED}$current_ctx (broken)${NC}"
                    fi
                else
                    echo -e "  ${BOLD}Current Context:${NC} ${YELLOW}Not set for this project${NC}"
                    echo -e "  ${BOLD}Global Context:${NC} ${BLUE}$(basename "$current_project")${NC}:${BLUE}$current_ctx${NC}"
                fi
            else
                echo -e "  ${YELLOW}No context set${NC}"
            fi

            # Show number of available contexts
            if [ -d "$contexts_dir" ]; then
                local contexts_count=$(ls -1 "$contexts_dir" 2>/dev/null | wc -l)
                echo -e "  ${BOLD}Available Contexts:${NC} ${CYAN}$contexts_count${NC}"
            else
                echo -e "  ${BOLD}Available Contexts:${NC} ${CYAN}0${NC}"
            fi

            # Show potential inventory contexts
            if [ -d "$inventories_dir" ]; then
                local scanned_count=0
                while IFS= read -r line; do
                    [ -n "$line" ] && ((scanned_count++))
                done < <(_scan_inventory_contexts "$project_root")
                echo -e "  ${BOLD}Discovered in inventories/:${NC} ${CYAN}$scanned_count${NC}"
            else
                echo -e "  ${BOLD}Discovered in inventories/:${NC} ${RED}directory not found${NC}"
            fi
            ;;
        "help"|"-h"|"--help")
            echo -e "${BOLD}Ansible Context Manager${NC}"
            echo ""
            echo -e "${BOLD}Project-based context management with inventories/ structure:${NC}"
            echo -e "  • Contexts are stored in ${YELLOW}.ansible-contexts/${NC} directory of your project"
            echo -e "  • Current context is stored globally in ${YELLOW}~/.ansible/contexts/current${NC}"
            echo -e "  • Scans ${YELLOW}inventories/${NC} directory for context folders/files"
            echo -e "  • Each folder in ${YELLOW}inventories/${NC} becomes a context"
            echo ""
            echo -e "${BOLD}Expected structure:${NC}"
            echo -e "  ${YELLOW}project/${NC}"
            echo -e "    ${YELLOW}├── inventories/${NC}"
            echo -e "    ${YELLOW}│   ├── prod/${NC}     ${CYAN}# becomes context 'prod'${NC}"
            echo -e "    ${YELLOW}│   ├── stage/${NC}    ${CYAN}# becomes context 'stage'${NC}"
            echo -e "    ${YELLOW}│   └── dev/${NC}      ${CYAN}# becomes context 'dev'${NC}"
            echo -e "    ${YELLOW}└── .ansible-contexts/${NC}"
            echo ""
            echo -e "${BOLD}Usage:${NC}"
            echo -e "  ${CYAN}ansible-ctx${NC}                    # Show current context"
            echo -e "  ${CYAN}ansible-ctx list${NC}               # List all contexts in current project"
            echo -e "  ${CYAN}ansible-ctx scan${NC}               # Scan inventories/ for contexts"
            echo -e "  ${CYAN}ansible-ctx import${NC}             # Auto-import contexts from inventories/"
            echo -e "  ${CYAN}ansible-ctx use${NC} ${BLUE}<name>${NC}         # Switch to context"
            echo -e "  ${CYAN}ansible-ctx add${NC} ${BLUE}<name>${NC} [${BLUE}<path>${NC}]  # Add context (auto-detects from inventories/)"
            echo -e "  ${CYAN}ansible-ctx remove${NC} ${BLUE}<name>${NC}      # Remove context"
            echo -e "  ${CYAN}ansible-ctx edit${NC} ${BLUE}<name>${NC}        # Edit context inventory path"
            echo -e "  ${CYAN}ansible-ctx clear${NC}              # Clear current context"
            echo -e "  ${CYAN}ansible-ctx status${NC}             # Show detailed status"
            echo -e "  ${CYAN}ansible-ctx help${NC}               # Show this help"
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            echo -e "Use '${CYAN}ansible-ctx help${NC}' for usage information"
            return 1
            ;;
    esac
}

# Function to get all available contexts (for autocompletion)
_get_all_contexts() {
    local project_root
    local search_dir="$(pwd)"

    while [ "$search_dir" != "/" ]; do
        if [ -d "$search_dir/.git" ] || [ -f "$search_dir/ansible.cfg" ] || [ -d "$search_dir/inventories" ]; then
            project_root="$search_dir"
            break
        fi
        search_dir="$(dirname "$search_dir")"
    done

    project_root="${project_root:-$(pwd)}"
    local contexts_dir="$project_root/.ansible-contexts"

    # Existing contexts
    if [ -d "$contexts_dir" ]; then
        ls "$contexts_dir" 2>/dev/null
    fi

    # Potential contexts from inventories/ (if not too many)
    local scanned_count=0
    while IFS= read -r line; do
        [ -n "$line" ] && ((scanned_count++))
    done < <(_scan_inventory_contexts "$project_root" 2>/dev/null)

    if [ $scanned_count -le 15 ]; then  # Don't overload autocompletion
        while IFS= read -r context; do
            [ -n "$context" ] && echo "$context"
        done < <(_scan_inventory_contexts "$project_root" 2>/dev/null)
    fi
}

# Auto-load context on shell startup
_ansible-ctx_autoload() {
    local global_contexts_dir="$HOME/.ansible/contexts"
    local current_file="$global_contexts_dir/current"

    if [ -f "$current_file" ]; then
        local current_info=$(cat "$current_file" 2>/dev/null)
        local current_project=$(echo "$current_info" | cut -d: -f1)
        local current_ctx=$(echo "$current_info" | cut -d: -f2)

        # Function to determine current project root
        local project_root
        local search_dir="$(pwd)"

        while [ "$search_dir" != "/" ]; do
            if [ -d "$search_dir/.git" ] || [ -f "$search_dir/ansible.cfg" ] || [ -d "$search_dir/inventories" ]; then
                project_root="$search_dir"
                break
            fi
            search_dir="$(dirname "$search_dir")"
        done

        # If not found, use current directory
        project_root="${project_root:-$(pwd)}"

        # Load context only if we're in the same project
        if [ "$current_project" = "$project_root" ] && [ -f "$project_root/.ansible-contexts/$current_ctx" ]; then
            local inventory_path=$(cat "$project_root/.ansible-contexts/$current_ctx" 2>/dev/null)
            if [ -n "$inventory_path" ]; then
                export ANSIBLE_INVENTORY="$inventory_path"
            fi
        fi
    fi
}

# Auto-load on startup
_ansible-ctx_autoload

# Auto-load on directory change (for zsh)
if [ -n "$ZSH_VERSION" ]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd _ansible-ctx_autoload
fi

# Additional function for quick switching (alias-style)
ansible_use() {
    ansible-ctx use "$1"
}

# Autocompletion for bash
_ansible-ctx_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        "use"|"remove"|"rm"|"edit")
            local contexts=$(_get_all_contexts)
            COMPREPLY=($(compgen -W "$contexts" -- "$cur"))
            ;;
        "add")
            # For add command suggest contexts from inventories/
            local project_root
            local search_dir="$(pwd)"

            while [ "$search_dir" != "/" ]; do
                if [ -d "$search_dir/.git" ] || [ -f "$search_dir/ansible.cfg" ] || [ -d "$search_dir/inventories" ]; then
                    project_root="$search_dir"
                    break
                fi
                search_dir="$(dirname "$search_dir")"
            done

            project_root="${project_root:-$(pwd)}"

            local available_contexts=""
            while IFS= read -r line; do
                [ -n "$line" ] && available_contexts="$available_contexts $line"
            done < <(_scan_inventory_contexts "$project_root")
            COMPREPLY=($(compgen -W "$available_contexts" -- "$cur"))
            ;;
        "ansible-ctx")
            COMPREPLY=($(compgen -W "list scan import use add remove edit clear status help" -- "$cur"))
            ;;
    esac
}

# Enable autocompletion for bash
if [ -n "$BASH_VERSION" ]; then
    complete -F _ansible-ctx_completion ansible-ctx
fi

alias ac='ansible-ctx'
alias acl='ansible-ctx list'
alias acs='ansible-ctx scan'
alias aci='ansible-ctx import'
alias acu='ansible-ctx use'
alias aca='ansible-ctx add'
alias acr='ansible-ctx remove'
alias ace='ansible-ctx edit'
alias acc='ansible-ctx clear'
alias acst='ansible-ctx status'
