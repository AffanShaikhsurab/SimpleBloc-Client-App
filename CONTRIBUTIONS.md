# CONTRIBUTING.md

## How to Contribute to SimpleBloc-Client-App

Thank you for considering contributing to our project! This document provides guidelines and instructions to help make the contribution process smooth and effective.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/yourusername/SimpleBloc-Client-App.git
   cd SimpleBloc-Client-App
   ```
3. **Set up the development environment**:
   ```bash
   npm install
   ```

## Development Process

1. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Make your changes**
3. **Test your changes**:
   ```bash
   npm test
   ```
4. **Ensure code quality**:
   ```bash
   npm run lint
   ```

## Pull Request Process

1. **Update documentation** as needed
2. **Add tests** for new features
3. **Ensure CI passes** on your pull request
4. **Update the README.md** with details of changes if applicable
5. **Submit your pull request** with a clear description of the changes

## Commit Message Guidelines

We follow conventional commits specification:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect the code's meaning
- **refactor**: Code changes that neither fix a bug nor add a feature
- **perf**: Changes that improve performance
- **test**: Adding or modifying tests
- **chore**: Changes to the build process or auxiliary tools

Example: `feat(auth): add user authentication flow`

## Verification

For security purposes, we verify all contributions using MD5 checksums. When submitting significant changes, please include an MD5 checksum of your contribution in your PR description.

```bash
# For Linux/Mac
md5sum your-changed-file.js

# For Windows
certutil -hashfile your-changed-file.js MD5
```

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license.

Thank you for your contributions!
