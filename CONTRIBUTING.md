# Contributing to FreeRADIUS Docker Setup

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Reporting Issues

- Check if the issue already exists
- Provide detailed information:
  - OS and Docker version
  - Steps to reproduce
  - Expected vs actual behavior
  - Relevant logs

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly:
   ```bash
   make clean
   make build
   make up
   make test
   ```
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Coding Standards

- **Docker**: Follow Docker best practices
- **Shell Scripts**: Use shellcheck for validation
- **Configuration**: Keep configs readable and well-commented
- **Documentation**: Update README.md for new features

### Testing Checklist

Before submitting a PR, ensure:

- [ ] Services start successfully
- [ ] Authentication works with test users
- [ ] Database connectivity is verified
- [ ] Health checks pass
- [ ] No security vulnerabilities introduced
- [ ] Documentation is updated

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/freeradius-docker.git
cd freeradius-docker

# Create .env from example
cp .env.example .env

# Build and test
make build
make up
make test
```

## Questions?

Feel free to open an issue for questions or discussions.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
