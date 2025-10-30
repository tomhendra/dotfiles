# Requirements Document

## Introduction

This feature addresses UI inconsistencies and duplicate output in the tomdot installation script's final steps. The installation process currently shows confusing duplicate "Next steps" sections, incorrect progress indicators, and validation steps that don't display proper status colors.

## Glossary

- **Installation Script**: The main `install.sh` script that orchestrates the tomdot setup process
- **UI Framework**: The Rock.js-inspired CLI framework in `lib/tomdot_ui.sh`
- **Symlink Step**: The dotfiles symlink creation phase of installation
- **Final Validation**: The validation phase that checks installation success
- **Status Indicators**: Visual symbols (◇, ✓) that show step progress and completion
- **Next Steps Section**: The informational box showing commands to run after installation

## Requirements

### Requirement 1

**User Story:** As a user running the tomdot installation, I want clean, non-repetitive output so that I can clearly understand the installation progress and next steps.

#### Acceptance Criteria

1. WHEN the symlink creation step completes, THE Installation Script SHALL display the step completion status once without duplication
2. THE Installation Script SHALL display the "Next steps" section only once at the end of the entire installation process
3. THE Installation Script SHALL NOT display progress indicators in incorrect locations or contexts
4. THE Installation Script SHALL ensure each step's output appears in the correct sequence without overlapping content

### Requirement 2

**User Story:** As a user monitoring installation progress, I want proper visual status indicators so that I can easily identify which steps are in progress, completed, or failed.

#### Acceptance Criteria

1. WHEN a validation step is in progress, THE Installation Script SHALL display blue status indicators
2. WHEN a validation step completes successfully, THE Installation Script SHALL display green status indicators with checkmarks
3. WHEN a validation step fails, THE Installation Script SHALL display red status indicators with error symbols
4. THE Installation Script SHALL maintain consistent status indicator colors throughout the validation process

### Requirement 3

**User Story:** As a user completing the installation, I want a clear final summary so that I know exactly what to do next without confusion.

#### Acceptance Criteria

1. WHEN the installation completes successfully, THE Installation Script SHALL display a single, clear "Next steps" section
2. THE Installation Script SHALL include only essential next step commands in the final output
3. THE Installation Script SHALL format the final summary in a clean, readable manner
4. THE Installation Script SHALL avoid displaying internal progress tracking information to the user

### Requirement 4

**User Story:** As a developer maintaining the installation script, I want proper separation between step execution and final reporting so that the UI output is predictable and maintainable.

#### Acceptance Criteria

1. THE Installation Script SHALL separate step execution logic from final status reporting
2. THE Installation Script SHALL ensure validation steps complete their UI updates before proceeding
3. THE Installation Script SHALL prevent UI framework functions from displaying duplicate content
4. THE Installation Script SHALL maintain clean state management between installation phases

### Requirement 5

**User Story:** As a user running the installation, I want concise validation output so that I can quickly see the overall status without being overwhelmed by verbose checking messages.

#### Acceptance Criteria

1. THE Installation Script SHALL display validation progress without showing individual "Checking..." messages for each item
2. WHEN validation completes successfully, THE Installation Script SHALL show a summary rather than detailed step-by-step output
3. WHEN validation encounters issues, THE Installation Script SHALL display detailed information only for failed items
4. THE Installation Script SHALL maintain thorough validation while minimizing output noise

### Requirement 6

**User Story:** As a user setting up ghostty terminal configuration, I want the symlink to be created correctly so that my terminal configuration works properly.

#### Acceptance Criteria

1. THE Installation Script SHALL create exactly one symlink for ghostty configuration without duplicates
2. THE Installation Script SHALL ensure the ghostty symlink points to the correct dotfiles directory
3. WHEN ghostty symlink creation fails, THE Installation Script SHALL provide clear error information
4. THE Installation Script SHALL validate that the ghostty symlink is functional after creation
