# Design Document

## Overview

The tomdot installation script has UI inconsistencies in its final output phase. The main issues are:

1. **Duplicate "Next steps" sections** - The script shows next steps after symlink creation AND after final validation
2. **Incorrect progress indicators** - "In progress (0/5 completed)" appears in wrong contexts
3. **Inconsistent status colors** - Final validation steps remain gray instead of showing proper blue/green status
4. **Repetitive output** - Multiple sections display the same information

The root cause is that the UI framework functions are being called multiple times without proper state management, and the final validation function (`tomdot_validate_installation`) starts its own UI section that conflicts with the main installation flow.

## Architecture

### Current Flow Issues

```
install.sh main()
├── tomdot_install()
│   ├── tomdot_execute_step("symlinks", "create_symlinks", ...)
│   │   ├── create_symlinks() outputs symlink creation details
│   │   └── Shows "Next steps" box (FIRST OCCURRENCE)
│   └── ui_show_progress() shows overall progress
├── ui_start_section "Final Validation" (STARTS NEW SECTION)
├── tomdot_validate_installation()
│   ├── ui_start_section "Validating Installation" (NESTED SECTION)
│   └── Individual validation checks with status indicators
└── Shows "Next steps" box again (SECOND OCCURRENCE)
```

### Target Flow

```
install.sh main()
├── tomdot_install()
│   ├── All installation steps (no next steps shown)
│   └── ui_show_progress() shows overall progress
├── Final validation as part of main flow (no separate section)
└── Single "Next steps" section at the very end
```

## Components and Interfaces

### 1. Installation Flow Controller (`install.sh`)

**Current Issues:**

- Calls `ui_start_section "Final Validation"` before validation
- Shows next steps box after validation regardless of where it was already shown
- Doesn't coordinate with the validation function's own UI calls

**Design Changes:**

- Remove the separate "Final Validation" section start
- Move final validation into the main installation flow
- Show next steps only once at the end
- Coordinate UI state between main flow and validation

### 2. Validation Function (`tomdot_validate_installation`)

**Current Issues:**

- Starts its own UI section with `ui_start_section "Validating Installation"`
- Uses inconsistent status indicators (gray instead of blue/green)
- Doesn't coordinate with the main installation UI flow

**Design Changes:**

- Remove the internal `ui_start_section` call
- Use consistent status indicators that match the main flow
- Return validation results without managing UI directly
- Allow the main flow to handle UI presentation

### 3. Symlink Creation Step (`create_symlinks`)

**Current Issues:**

- The symlink step completion triggers a "Next steps" display
- This happens before final validation, causing duplication

**Design Changes:**

- Remove any "Next steps" display from individual steps
- Let only the main installation flow show final next steps

### 4. UI Framework (`tomdot_ui.sh`)

**Current Issues:**

- No state management to prevent duplicate sections
- Status indicators don't maintain consistent colors
- No coordination between nested UI sections

**Design Changes:**

- Add state tracking to prevent duplicate "Next steps" displays
- Ensure consistent status indicator colors throughout
- Provide a way to suppress nested section starts when already in a section

## Data Models

### UI State Management

```bash
# New global variables to track UI state
TOMDOT_UI_NEXT_STEPS_SHOWN=false
TOMDOT_UI_IN_SECTION=false
TOMDOT_UI_CURRENT_SECTION=""
```

### Validation Result Structure

```bash
# Validation function should return structured results
tomdot_validate_installation() {
    # Returns:
    # - Exit code 0/1 for success/failure
    # - Outputs validation details for main flow to display
    # - No UI section management
}
```

## Error Handling

### Validation Display Errors

**Problem:** Validation steps show gray status instead of proper colors
**Solution:** Ensure validation output uses the same UI functions as installation steps

### Duplicate Content Prevention

**Problem:** Multiple "Next steps" sections appear
**Solution:** Add state tracking to prevent duplicate displays

### Section Nesting Issues

**Problem:** Nested UI sections create confusing output
**Solution:** Flatten the UI hierarchy and coordinate section management

## Testing Strategy

### Manual Testing Scenarios

1. **Fresh Installation Test**

   - Run complete installation
   - Verify single "Next steps" section appears only at the end
   - Verify validation steps show proper blue→green status progression
   - Verify no duplicate progress indicators

2. **Resume Installation Test**

   - Interrupt installation partway through
   - Resume installation
   - Verify UI consistency in resume flow

3. **Individual Step Test**
   - Run individual steps (e.g., `--step symlinks`)
   - Verify no duplicate UI elements
   - Verify proper status indicators

### Validation Checks

1. **UI Output Parsing**

   - Count occurrences of "Next steps" in output
   - Verify status indicator color consistency
   - Check for proper section hierarchy

2. **State Management**

   - Verify UI state variables are properly managed
   - Test prevention of duplicate content

3. **Integration Testing**
   - Test all installation modes (fresh, resume, individual steps)
   - Verify consistent UI behavior across all modes

## Implementation Approach

### Phase 1: Fix Main Installation Flow

- Modify `install.sh` to remove duplicate "Final Validation" section
- Coordinate validation display with main flow
- Ensure single "Next steps" display

### Phase 2: Fix Validation Function

- Remove internal UI section management from `tomdot_validate_installation`
- Standardize status indicator usage
- Return structured results for main flow to display

### Phase 3: Add UI State Management

- Implement state tracking in UI framework
- Prevent duplicate content display
- Ensure consistent status colors

### Phase 4: Clean Up Step Functions

- Remove any "Next steps" displays from individual steps
- Ensure all UI output goes through main flow coordination
