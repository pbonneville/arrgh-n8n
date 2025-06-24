# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please follow these steps:

1. **Do not** open a public issue
2. Send a description of the vulnerability to the repository owner via GitHub's private vulnerability reporting feature
3. Include steps to reproduce if possible
4. Allow up to 48 hours for an initial response

## Security Features

This repository has the following security features enabled:

- **CodeQL Analysis**: Automated code scanning for vulnerabilities
- **Dependabot**: Automated dependency updates for security patches
- **Secret Scanning**: Prevents accidental commits of secrets and credentials

## Best Practices

When contributing to this project:

- Never commit secrets, API keys, or credentials
- Use environment variables for sensitive configuration
- Follow the principle of least privilege for all permissions
- Keep dependencies up to date