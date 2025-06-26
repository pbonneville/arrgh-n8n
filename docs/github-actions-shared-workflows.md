# GitHub Actions Shared Workflows Documentation

## Overview

All `arrgh-*` repositories use a centralized GitHub Actions workflow system hosted in the `arrgh-hub` repository. This approach ensures consistency, reduces maintenance overhead, and allows for easy updates across all projects.

## Architecture

### Centralized Workflows (arrgh-hub)
- **Location**: `pbonneville/arrgh-hub/.github/workflows/`
- **Reusable workflows**:
  - `reusable-pr-validation.yml` - PR validation, size checks, labeling
  - `reusable-pr-approved.yml` - Post-approval automation, auto-merge

### Local Wrapper Workflows
Each repository contains minimal wrapper workflows that call the centralized ones:
- `.github/workflows/pr-validation.yml`
- `.github/workflows/pr-approved.yml`

## Features

### PR Validation
- **Conventional commit validation**: Ensures PR titles follow format (feat:, fix:, etc.)
- **Size limits**: Configurable per repository type
- **Auto-labeling**: Based on PR type
- **Description validation**: Checks for required sections
- **Security scanning**: Detects security-related changes
- **Metrics reporting**: PR size and quality metrics

### PR Approval & Merge
- **Auto-merge**: For safe PR types (docs, tests, style)
- **Release notes**: Automatic generation for features/fixes
- **Branch cleanup**: Auto-delete feature branches after merge
- **Contributor thanks**: Personalized thank you messages
- **Breaking change detection**: Creates issues for breaking changes

## Repository-Specific Configurations

### arrgh-excalidraw (Frontend/Next.js)
```yaml
small_max_lines: 500    # Frontend has more boilerplate
small_max_files: 12
enable_auto_merge: true
auto_merge_types: 'docs,test,style,chore'
```

### arrgh-fastapi (Python/Backend)
```yaml
small_max_lines: 300    # Python is more concise
small_max_files: 8
enable_auto_merge: true
auto_merge_types: 'docs,test,style,chore'
```

### arrgh-ios (Swift/Mobile)
```yaml
small_max_lines: 400
small_max_files: 10
enable_auto_merge: false    # iOS needs manual testing
auto_merge_types: 'docs'    # Only docs auto-merge
```

### arrgh-n8n (Infrastructure)
```yaml
small_max_lines: 200    # Config changes should be minimal
small_max_files: 5
enable_auto_merge: true
auto_merge_types: 'docs,chore'    # Careful with infrastructure
```

## How It Works

1. **PR Created/Updated**: Triggers `pr-validation.yml` wrapper
2. **Wrapper calls arrgh-hub**: Uses `pbonneville/arrgh-hub/.github/workflows/reusable-pr-validation.yml@main`
3. **Validation runs**: Size checks, labeling, description validation
4. **PR Approved**: Triggers `pr-approved.yml` wrapper
5. **Automation runs**: Auto-merge, release notes, cleanup

## Benefits

- **Centralized Management**: Updates in arrgh-hub apply to all repos instantly
- **Minimal Footprint**: Each repo only needs ~60 lines of workflow config
- **Consistency**: Same standards across all projects
- **Flexibility**: Per-repo customization through parameters

## Maintenance

### Updating Workflows
1. Make changes in `arrgh-hub` repository
2. Changes take effect immediately in all repos
3. No need to update individual repositories

### Adding New Repository
1. Create `.github/workflows/` directory
2. Copy wrapper workflows from any existing arrgh repo
3. Adjust parameters for repository type
4. Add PR template

### Troubleshooting
- **Workflow not found**: Ensure arrgh-hub is public or has proper access settings
- **Permission errors**: Check repository permissions in workflow files
- **Labels missing**: Workflows will create labels automatically on first run

## Security Notes

- Workflows from public repos (arrgh-hub) can be called by any repository
- Each repo must explicitly opt-in by creating wrapper workflows
- Permissions are scoped per workflow execution
- No secrets are shared between repositories

## Future Enhancements

- Repository-specific configuration files (`.github/pr-automation-config.yml`)
- Custom validation rules per language/framework
- Integration with deployment workflows
- Automated dependency updates coordination