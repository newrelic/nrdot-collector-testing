# nrdot-collector-testing Development Guidelines

## Helm Chart Development

### Testing Requirements

**CRITICAL**: Every change to the Helm chart MUST include corresponding unit tests.

- Any modification to chart templates (`helm/collector/templates/*.yaml`) requires a new test or modification to existing tests in `helm/collector/tests/*_test.yaml`
- Tests use the helm-unittest plugin syntax
- Test files are organized by template:
  - `daemonset_test.yaml` - Tests for DaemonSet template
  - `deployment_test.yaml` - Tests for Deployment template
  - `secret_test.yaml` - Tests for Secret template and env var injection
- Tests should cover:
  - Default behavior
  - Edge cases (empty values, missing optional fields)
  - Interaction between different values
  - Both daemonset and deployment modes where applicable

### Versioning Requirements

**CRITICAL**: Every change to the chart requires a version bump in `helm/collector/Chart.yaml`.

#### Default Versioning Strategy
- **Default to minor version bumps** (e.g., 0.1.0 → 0.2.0)
- Only use patch or major version bumps when specifically requested
- Current version: 0.2.0

### Running Tests

```bash
cd helm/collector
helm unittest .
```