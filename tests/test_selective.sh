#!/usr/bin/env bash

# Tests for selective installation system

# Source the selective installation library
source "$(dirname "${BASH_SOURCE[0]}")/../lib/selective.sh"

# Test component definition parsing
test_component_definition_parsing() {
    # Test valid component
    local definition
    definition=$(parse_component_definition "prerequisites")
    assert_contains "$definition" "System prerequisites" "Should parse component description"

    # Test invalid component
    definition=$(parse_component_definition "nonexistent_component")
    local exit_code=$?
    assert_failure $exit_code "Should fail for non-existent component"
    assert_contains "$definition" "unknown" "Should return unknown for invalid component"
}

# Test component metadata retrieval
test_component_metadata_retrieval() {
    # Test component description
    local description
    description=$(get_component_description "prerequisites")
    assert_contains "$description" "System prerequisites" "Should get correct description"

    # Test component category
    local category
    category=$(get_component_category "prerequisites")
    assert_equals "system" "$category" "Should get correct category"

    # Test required component check
    if ! is_component_required "prerequisites"; then
        echo "Prerequisites should be required"
        return 1
    fi

    if is_component_required "rust"; then
        echo "Rust should not be required"
        return 1
    fi

    # Test component dependencies
    local deps
    deps=$(get_component_dependencies "github_auth")
    assert_contains "$deps" "ssh_setup" "GitHub auth should depend on SSH setup"
}

# Test component listing
test_component_listing() {
    # Test getting all components
    local all_components
    all_components=$(get_all_components)
    assert_contains "$all_components" "prerequisites" "Should list prerequisites"
    assert_contains "$all_components" "homebrew" "Should list homebrew"
    assert_contains "$all_components" "symlinks" "Should list symlinks"

    # Test getting components by category
    local system_components
    system_components=$(get_components_by_category "system")
    assert_contains "$system_components" "prerequisites" "Should list system components"

    local language_components
    language_components=$(get_components_by_category "languages")
    assert_contains "$language_components" "rust" "Should list language components"
    assert_contains "$language_components" "nodejs" "Should list language components"

    # Test getting all categories
    local categories
    categories=$(get_all_categories)
    assert_contains "$categories" "system" "Should list system category"
    assert_contains "$categories" "languages" "Should list languages category"
    assert_contains "$categories" "packages" "Should list packages category"
}

# Test dependency resolution
test_dependency_resolution() {
    # Test simple dependency resolution
    local deps
    deps=$(resolve_dependencies "ssh_setup")
    assert_contains "$deps" "prerequisites" "SSH setup should include prerequisites"
    assert_contains "$deps" "ssh_setup" "Should include the component itself"

    # Test complex dependency resolution
    deps=$(resolve_dependencies "github_auth")
    assert_contains "$deps" "prerequisites" "Should include transitive dependencies"
    assert_contains "$deps" "ssh_setup" "Should include direct dependencies"
    assert_contains "$deps" "github_auth" "Should include the component itself"

    # Test dependency order (prerequisites should come before dependents)
    local deps_array=($deps)
    local prereq_index=-1
    local ssh_index=-1
    local github_index=-1

    for i in "${!deps_array[@]}"; do
        case "${deps_array[$i]}" in
            "prerequisites") prereq_index=$i ;;
            "ssh_setup") ssh_index=$i ;;
            "github_auth") github_index=$i ;;
        esac
    done

    if [[ $prereq_index -ge $ssh_index ]] || [[ $ssh_index -ge $github_index ]]; then
        echo "Dependencies should be resolved in correct order"
        return 1
    fi
}

# Test component selection validation
test_component_selection_validation() {
    # Test valid selection
    validate_component_selection "prerequisites" "ssh_setup" "homebrew"
    local exit_code=$?
    assert_success $exit_code "Valid component selection should pass validation"

    # Test selection with unknown component
    validate_component_selection "prerequisites" "unknown_component" >/dev/null 2>&1
    exit_code=$?
    assert_failure $exit_code "Selection with unknown component should fail validation"

    # Test selection missing required components
    validate_component_selection "rust" "nodejs" >/dev/null 2>&1
    exit_code=$?
    assert_failure $exit_code "Selection missing required components should fail validation"
}

# Test component selection expansion
test_component_selection_expansion() {
    # Test expansion with dependencies
    local expanded
    expanded=$(expand_component_selection "github_auth")

    assert_contains "$expanded" "prerequisites" "Should expand to include prerequisites"
    assert_contains "$expanded" "ssh_setup" "Should expand to include SSH setup"
    assert_contains "$expanded" "github_auth" "Should include original component"

    # Test expansion with multiple components
    expanded=$(expand_component_selection "homebrew" "nodejs")

    assert_contains "$expanded" "prerequisites" "Should include shared dependencies"
    assert_contains "$expanded" "homebrew" "Should include homebrew"
    assert_contains "$expanded" "nodejs" "Should include nodejs"
}

# Test command line option parsing
test_command_line_parsing() {
    # Test component selection parsing
    local options
    options=$(parse_selective_options --components "ssh_setup,homebrew")

    assert_contains "$options" '"ssh_setup"' "Should parse component selection"
    assert_contains "$options" '"homebrew"' "Should parse multiple components"

    # Test category selection parsing
    options=$(parse_selective_options --categories "languages,packages")

    assert_contains "$options" '"languages"' "Should parse category selection"
    assert_contains "$options" '"packages"' "Should parse multiple categories"

    # Test exclusion parsing
    options=$(parse_selective_options --exclude "rust,nodejs")

    assert_contains "$options" '"rust"' "Should parse exclusions"
    assert_contains "$options" '"nodejs"' "Should parse multiple exclusions"

    # Test dry run flag
    options=$(parse_selective_options --dry-run)

    assert_contains "$options" '"dry_run": true' "Should parse dry run flag"

    # Test help flag
    options=$(parse_selective_options --help)

    assert_contains "$options" '"show_help": true' "Should parse help flag"
}

# Test installation plan building
test_installation_plan_building() {
    # Test plan with specific components
    local options='{"selected_components": ["homebrew"], "excluded_components": [], "categories": [], "dry_run": false, "show_help": false}'
    local plan
    plan=$(build_installation_plan "$options")

    assert_contains "$plan" "prerequisites" "Plan should include dependencies"
    assert_contains "$plan" "homebrew" "Plan should include selected component"

    # Test plan with categories
    options='{"selected_components": [], "excluded_components": [], "categories": ["languages"], "dry_run": false, "show_help": false}'
    plan=$(build_installation_plan "$options")

    assert_contains "$plan" "rust" "Plan should include language components"
    assert_contains "$plan" "nodejs" "Plan should include language components"

    # Test plan with exclusions
    options='{"selected_components": [], "excluded_components": ["rust"], "categories": ["languages"], "dry_run": false, "show_help": false}'
    plan=$(build_installation_plan "$options")

    assert_contains "$plan" "nodejs" "Plan should include non-excluded components"
    if echo "$plan" | grep -q "rust"; then
        echo "Plan should not include excluded components"
        return 1
    fi
}

# Test dry run preview
test_dry_run_preview() {
    local test_plan=("prerequisites" "ssh_setup" "homebrew")

    # Test dry run preview generation
    local preview
    preview=$(show_dry_run_preview "${test_plan[@]}")

    assert_contains "$preview" "DRY RUN" "Should show dry run header"
    assert_contains "$preview" "prerequisites" "Should list components"
    assert_contains "$preview" "ssh_setup" "Should list components"
    assert_contains "$preview" "homebrew" "Should list components"
    assert_contains "$preview" "Total components: 3" "Should show component count"

    # Test empty plan
    preview=$(show_dry_run_preview)

    assert_contains "$preview" "No components selected" "Should handle empty plan"
}

# Test available components display
test_available_components_display() {
    local display
    display=$(show_available_components)

    assert_contains "$display" "AVAILABLE INSTALLATION COMPONENTS" "Should show header"
    assert_contains "$display" "Category:" "Should show categories"
    assert_contains "$display" "prerequisites" "Should list components"
    assert_contains "$display" "Usage Examples:" "Should show usage examples"
}

# Test selective help display
test_selective_help_display() {
    local help
    help=$(show_selective_help)

    assert_contains "$help" "Selective Installation Options" "Should show help header"
    assert_contains "$help" "OPTIONS:" "Should show options section"
    assert_contains "$help" "EXAMPLES:" "Should show examples section"
    assert_contains "$help" "COMPONENT CATEGORIES:" "Should show categories section"
    assert_contains "$help" "DEPENDENCY RESOLUTION:" "Should show dependency info"
}

# Test selective installation execution (dry run)
test_selective_installation_execution() {
    init_state_dir

    # Test dry run execution
    local options='{"selected_components": ["prerequisites"], "excluded_components": [], "categories": [], "dry_run": true, "show_help": false}'
    local test_plan=("prerequisites")

    execute_selective_installation "$options" "${test_plan[@]}"
    local exit_code=$?

    assert_success $exit_code "Dry run execution should succeed"

    # Test help execution
    options='{"selected_components": [], "excluded_components": [], "categories": [], "dry_run": false, "show_help": true}'

    execute_selective_installation "$options"
    exit_code=$?

    assert_success $exit_code "Help execution should succeed"
}

# Test main selective installation function
test_run_selective_installation() {
    # Test help request
    run_selective_installation --help >/dev/null
    local exit_code=$?

    assert_success $exit_code "Help request should succeed"

    # Test dry run
    run_selective_installation --components "prerequisites" --dry-run >/dev/null
    exit_code=$?

    assert_success $exit_code "Dry run should succeed"

    # Test invalid component
    run_selective_installation --components "invalid_component" >/dev/null 2>&1
    exit_code=$?

    assert_failure $exit_code "Invalid component should fail"
}

# Test component definition completeness
test_component_definition_completeness() {
    # Test that all expected components are defined
    local expected_components=(
        "prerequisites"
        "ssh_setup"
        "github_auth"
        "clone_dotfiles"
        "clone_repos"
        "homebrew"
        "rust"
        "nodejs"
        "global_packages"
        "configurations"
        "symlinks"
        "final_validation"
    )

    for component in "${expected_components[@]}"; do
        local definition
        definition=$(parse_component_definition "$component")
        local exit_code=$?

        assert_success $exit_code "Component '$component' should be defined"
        assert_not_contains "$definition" "unknown" "Component '$component' should have valid definition"
    done
}

# Test dependency chain validation
test_dependency_chain_validation() {
    # Test that dependency chains are valid (no circular dependencies)
    local components=($(get_all_components))

    for component in $components; do
        local deps
        deps=$(resolve_dependencies "$component" 2>/dev/null)
        local exit_code=$?

        assert_success $exit_code "Dependency resolution for '$component' should succeed"

        # Check that component appears in its own dependency list (should be last)
        assert_contains "$deps" "$component" "Component '$component' should appear in its dependency list"
    done
}

# Test category consistency
test_category_consistency() {
    # Test that all components have valid categories
    local components=($(get_all_components))
    local valid_categories=("system" "security" "setup" "packages" "languages" "development" "validation")

    for component in $components; do
        local category
        category=$(get_component_category "$component")

        local category_valid=false
        for valid_cat in "${valid_categories[@]}"; do
            if [[ "$category" == "$valid_cat" ]]; then
                category_valid=true
                break
            fi
        done

        if [[ "$category_valid" != true ]]; then
            echo "Component '$component' has invalid category: '$category'"
            return 1
        fi
    done
}

# Test required components consistency
test_required_components_consistency() {
    # Test that required components form a valid minimal set
    local all_components=($(get_all_components))
    local required_components=()

    for component in $all_components; do
        if is_component_required "$component"; then
            required_components+=("$component")
        fi
    done

    # Should have at least some required components
    if [[ ${#required_components[@]} -eq 0 ]]; then
        echo "Should have at least some required components"
        return 1
    fi

    # Required components should be installable together
    validate_component_selection "${required_components[@]}"
    local exit_code=$?

    assert_success $exit_code "Required components should form a valid selection"
}

# Test edge cases in component selection
test_component_selection_edge_cases() {
    # Test empty selection
    local options='{"selected_components": [], "excluded_components": [], "categories": [], "dry_run": false, "show_help": false}'
    local plan
    plan=$(build_installation_plan "$options")

    # Should default to all components
    assert_contains "$plan" "prerequisites" "Empty selection should default to all components"

    # Test excluding all components of a category
    options='{"selected_components": [], "excluded_components": ["rust", "nodejs"], "categories": ["languages"], "dry_run": false, "show_help": false}'
    plan=$(build_installation_plan "$options")

    # Should result in empty or minimal plan for that category
    if echo "$plan" | grep -q "rust\|nodejs"; then
        echo "Excluded components should not appear in plan"
        return 1
    fi

    # Test conflicting selections (select and exclude same component)
    options='{"selected_components": ["rust"], "excluded_components": ["rust"], "categories": [], "dry_run": false, "show_help": false}'
    plan=$(build_installation_plan "$options")

    # Exclusion should take precedence
    if echo "$plan" | grep -q "rust"; then
        echo "Excluded components should not appear even if selected"
        return 1
    fi
}
