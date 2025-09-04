# Pre-commit Setup Guide

This project uses pre-commit hooks to ensure code quality and consistency across both backend (Python/Django) and frontend (Flutter/Dart).

## 🚀 **Quick Setup**

### 1. Install pre-commit globally
```bash
pip install pre-commit
```

### 2. Install backend dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 3. Install pre-commit hooks
```bash
# Install root-level hooks
pre-commit install

# Install backend-specific hooks
cd backend
pre-commit install

# Install frontend-specific hooks
cd frontend
pre-commit install
```

## 🔧 **What Each Hook Does**

### **Backend (Python/Django)**
- **Black**: Code formatting (88 character line length)
- **isort**: Import sorting and organization
- **flake8**: Linting and style checking
- **flake8-django**: Django-specific linting rules
- **mypy**: Type checking
- **bandit**: Security vulnerability scanning
- **General checks**: Merge conflicts, file formatting, etc.

### **Frontend (Flutter/Dart)**
- **dart format**: Code formatting
- **dart analyzer**: Static analysis and error checking
- **flutter analyze**: Flutter-specific analysis
- **YAML/JSON validation**: Configuration file validation
- **General checks**: File formatting, merge conflicts, etc.

## 📝 **Usage**

### **Automatic (Recommended)**
Hooks run automatically on every commit. If any hook fails, the commit is blocked until issues are fixed.

### **Manual Run**
```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run black

# Run on specific files
pre-commit run --files path/to/file.py
```

### **Skip Hooks (Emergency)**
```bash
git commit -m "Emergency fix" --no-verify
```

## 🛠️ **Fixing Issues**

### **Auto-fixable Issues**
Many issues can be fixed automatically:
```bash
# Format Python code
cd backend
black .
isort .

# Format Dart code
cd frontend
dart format .
```

### **Manual Fixes**
- **flake8 errors**: Fix linting issues manually
- **mypy errors**: Add type hints or ignore comments
- **bandit warnings**: Review security concerns

## 📁 **Configuration Files**

- **Root**: `.pre-commit-config.yaml` - Main configuration
- **Backend**: `backend/.pre-commit-config.yaml` - Python-specific hooks
- **Frontend**: `frontend/.pre-commit-config.yaml` - Flutter-specific hooks

## 🔄 **Updating Hooks**

```bash
# Update all hooks to latest versions
pre-commit autoupdate

# Update specific repository
pre-commit autoupdate --freeze
```

## 🚨 **Troubleshooting**

### **Common Issues**
1. **Hook fails on existing code**: Run `pre-commit run --all-files` to fix all files
2. **Performance issues**: Hooks only run on changed files by default
3. **Version conflicts**: Ensure Python/Flutter versions match requirements

### **Reset Hooks**
```bash
pre-commit uninstall
pre-commit install
```

## 📊 **Benefits**

- **Consistent code style** across the entire project
- **Catch errors early** before they reach production
- **Automated code quality** checks
- **Team collaboration** with standardized formatting
- **Security scanning** for vulnerabilities
- **Type safety** with mypy and Dart analyzer
