# Implementation Plan

- [x] 1. Fix main installation flow in install.sh

  - Remove duplicate "Final Validation" section start that creates nested UI sections
  - Coordinate final validation display with main installation flow
  - Ensure single "Next steps" display only at the very end
  - _Requirements: 1.1, 1.3, 3.1, 3.2_

- [x] 2. Refactor validation function to remove UI management

  - [x] 2.1 Remove internal ui_start_section call from tomdot_validate_installation

    - Modify tomdot_validate_installation in lib/tomdot_utils.sh to remove the ui_start_section "Validating Installation" call
    - Keep the validation logic but let the main flow handle UI presentation
    - _Requirements: 2.1, 2.2, 4.2_

  - [x] 2.2 Standardize validation output formatting
    - Ensure validation checks use consistent status indicator colors (blue for in-progress, green for success)
    - Format validation output to integrate cleanly with main installation flow
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Add UI state management to prevent duplicates

  - [x] 3.1 Implement state tracking in tomdot_ui.sh

    - Add global variables to track UI state (TOMDOT_UI_NEXT_STEPS_SHOWN, TOMDOT_UI_IN_SECTION)
    - Modify ui_bordered_box function to check state before displaying "Next steps"
    - _Requirements: 1.2, 1.4, 4.3_

  - [x] 3.2 Update main flow to use state management
    - Modify install.sh to set UI state flags appropriately
    - Ensure "Next steps" is only shown once at the end of successful installation
    - _Requirements: 1.1, 1.2, 3.1, 3.3_

- [x] 4. Clean up symlink step output

  - Remove any "Next steps" or progress indicator displays from create_symlinks function
  - Ensure symlink creation step only outputs its specific results without final summary information
  - _Requirements: 1.1, 1.4, 4.1_

- [x] 5. Integrate validation into main flow seamlessly

  - [x] 5.1 Modify install.sh validation call

    - Update the final validation section to display validation as part of main flow
    - Remove the separate ui_start_section "Final Validation" call
    - Display validation results with proper status indicators
    - _Requirements: 2.1, 2.2, 4.2_

  - [x] 5.2 Ensure consistent status progression
    - Make validation steps show blue indicators during progress and green on completion
    - Maintain visual consistency with installation step indicators
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 6. Reduce verbose validation output

  - [x] 6.1 Simplify validation check messages

    - Remove individual "Checking file:", "Checking tool:", "Checking symlink:" messages
    - Show only summary results or failed items
    - Keep validation thorough but reduce noise in output
    - _Requirements: 1.1, 2.1, 3.3_

  - [x] 6.2 Implement concise validation reporting
    - Display validation progress with a single progress indicator
    - Show detailed output only for failures or issues
    - Maintain the same validation logic but streamline the display
    - _Requirements: 1.1, 2.1, 3.3_

- [-] 7. Fix ghostty symlink configuration issues

  - [x] 7.1 Remove duplicate ghostty entries

    - Fix duplicate ghostty entries in TOMDOT_SYMLINKS array in lib/tomdot_utils.sh
    - Fix duplicate ghostty entries in create_symlinks function in lib/tomdot_installer.sh
    - Ensure ghostty directory symlink is created correctly
    - _Requirements: 4.1, 4.2_

  - [ ] 7.2 Verify ghostty symlink creation
    - Test that ghostty configuration directory symlink works properly
    - Ensure ~/.config/ghostty points to ~/.dotfiles/ghostty correctly
    - Validate that ghostty can read its configuration from the symlinked location
    - _Requirements: 4.1, 4.2_

- [-] 8. Fix visual gap in symlink step completion

  - Remove extra empty line after symlink step completion
  - Ensure proper connector flow between symlink step and validation
  - _Requirements: 1.1, 2.2_
