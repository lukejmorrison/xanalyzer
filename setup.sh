#!/bin/bash

# Function to check if a command is installed
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if a file exists
file_exists() {
  [ -f "$1" ]
}

# Function to check if a directory exists
directory_exists() {
  [ -d "$1" ]
}

# Function to check if a virtual environment is activated
virtual_environment_activated() {
  [ -n "$VIRTUAL_ENV" ]
}

# Function to check if a Node.js dependency is installed
node_dependency_installed() {
  local package_json="$1"
  local dependency="$2"
  local dependency_version=$(grep "\"$dependency\"" "$package_json" | awk -F '[:,]' '{print $2}' | tr -d '"' | tr -d ' ')
  if [ -z "$dependency_version" ]; then
    return 1
  fi
  return 0
}

# Function to check if a Python dependency is installed
python_dependency_installed() {
  local dependency="$1"
  pip3 show "$dependency" > /dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
  echo "Checking dependencies..."

  # Check Node.js and npm
  if ! command_exists node; then
    echo "Error: Node.js is not installed."
    return 1
  fi
  if ! command_exists npm; then
    echo "Error: npm is not installed."
    return 1
  fi

  # Check Python 3
  if ! command_exists python3; then
    echo "Error: Python 3 is not installed."
    return 1
  fi

  # Check for package.json
  if ! file_exists "/opt/xanalyzer/src/package.json"; then
    echo "Error: package.json not found in /opt/xanalyzer/src/"
    return 1
  fi

  # Check for node_modules
  if ! directory_exists "/opt/xanalyzer/src/node_modules"; then
    echo "Warning: node_modules/ not found. Run 'npm install' in /opt/xanalyzer/src/"
  fi

  # Check for .env
  if ! file_exists "/opt/xanalyzer/src/.env"; then
    echo "Error: .env not found in /opt/xanalyzer/src/"
    return 1
  fi

  # Check for app.js
  if ! file_exists "/opt/xanalyzer/src/app.js"; then
    echo "Error: app.js not found in /opt/xanalyzer/src/"
    return 1
  fi

  # Check for ecosystem.config.js
  if ! file_exists "/opt/xanalyzer/ecosystem.config.js"; then
    echo "Error: ecosystem.config.js not found in /opt/xanalyzer/"
    return 1
  fi

  # Check for start_app.sh
  if ! file_exists "/opt/xanalyzer/start_app.sh"; then
    echo "Error: start_app.sh not found in /opt/xanalyzer/"
    return 1
  fi

  # Check for virtual environment
  if ! directory_exists "/opt/xanalyzer/src/.venv"; then
    echo "Warning: Virtual environment not found. Run 'python3 -m venv .venv' in /opt/xanalyzer/src/"
  fi

  # Check if virtual environment is activated
  if ! virtual_environment_activated; then
    echo "Warning: Virtual environment is not activated. Run 'source /opt/xanalyzer/src/.venv/bin/activate'"
  fi

  # Check for xanalyzer_test.py
  if ! file_exists "/opt/xanalyzer/src/xanalyzer_test.py"; then
    echo "Error: xanalyzer_test.py not found in /opt/xanalyzer/src/"
    return 1
  fi

  # Check for test.log
  if ! file_exists "/opt/xanalyzer/src/test.log"; then
    echo "Warning: test.log not found in /opt/xanalyzer/src/"
  fi

  # Check for .gitignore
  if ! file_exists "/opt/xanalyzer/.gitignore"; then
    echo "Warning: .gitignore not found in /opt/xanalyzer/"
  fi

  # Check Node.js dependencies (using package.json)
  echo "Checking Node.js dependencies..."
  required_node_dependencies=("axios" "dotenv" "express" "express-session" "winston")
  for dependency in "${required_node_dependencies[@]}"; do
    if ! node_dependency_installed "/opt/xanalyzer/src/package.json" "$dependency"; then
      echo "Error: Node.js dependency '$dependency' is missing or not correctly defined in package.json. Run 'npm install' in /opt/xanalyzer/src/"
      return 1
    fi
  done

  # Check Python dependencies (using pip list)
  echo "Checking Python dependencies..."
  required_python_dependencies=("tweepy" "requests")
  for dependency in "${required_python_dependencies[@]}"; do
    if ! python_dependency_installed "$dependency"; then
      echo "Error: Python dependency '$dependency' is missing. Run 'pip3 install $dependency' in the activated virtual environment."
      return 1
    fi
  done

  echo "All dependencies appear to be installed."
  return 0
}

# Run the check_dependencies function
check_dependencies

# Exit with the correct code
exit $?
