#!/bin/bash

# Check if the script is run with sudo
if [[ $EUID -eq 0 ]]; then
  echo "Error: This script should not be run with sudo."
  exit 1
fi

# Check if the script is run in the correct directory
if [[ $(pwd) != "/opt/xanalyzer" ]]; then
  echo "Error: This script must be run in /opt/xanalyzer directory."
  exit 1
fi

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

# Function to create the virtual environment
create_virtual_environment() {
  echo "Creating virtual environment..."
  python3 -m venv /opt/xanalyzer/src/.venv
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment."
    return 1
  fi
  echo "Virtual environment created successfully."
  
  # Install python dependencies in the virtual environment
  source /opt/xanalyzer/src/.venv/bin/activate
  echo "Installing Python dependencies..."
  pip3 install --upgrade pip
  required_python_dependencies=("tweepy" "requests")
  for dependency in "${required_python_dependencies[@]}"; do
    if ! python_dependency_installed "$dependency"; then
      echo "Installing $dependency..."
      pip3 install "$dependency"
      if [ $? -ne 0 ]; then
        echo "Error: Failed to install $dependency"
        deactivate
        return 1
      fi
    fi
  done
  echo "Python dependencies installed successfully."
  return 0
}

# Function to install node dependencies
install_node_dependencies() {
  echo "Installing Node.js dependencies..."
  cd /opt/xanalyzer/src/
  npm install
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install Node.js dependencies."
    return 1
  fi
  cd ..
  echo "Node.js dependencies installed successfully."
  return 0
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
    echo "Warning: node_modules/ not found."
    if ! install_node_dependencies; then
      return 1
    fi
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
    if ! create_virtual_environment; then
      return 1
    fi
  fi
  
  # Activate the virtual environment
  source /opt/xanalyzer/src/.venv/bin/activate

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
      echo "Error: Node.js dependency '$dependency' is missing or not correctly defined in package.json."
      return 1
    fi
  done

  # Check Python dependencies (using pip list)
  echo "Checking Python dependencies..."
  required_python_dependencies=("tweepy" "requests")
  for dependency in "${required_python_dependencies[@]}"; do
    if ! python_dependency_installed "$dependency"; then
      echo "Error: Python dependency '$dependency' is missing."
      return 1
    fi
  done

  # Check for certificate and key files (check symbolic links and readability)
  echo "Checking for certificate and key files..."
  CERT_PATH="/etc/letsencrypt/live/xanalyzer.wizwam.com/fullchain.pem"
  KEY_PATH="/etc/letsencrypt/live/xanalyzer.wizwam.com/privkey.pem"
  
  if ! file_exists "$CERT_PATH"; then
    echo "Error: Certificate symbolic link $CERT_PATH not found."
    return 1
  fi
  if ! [ -r "$CERT_PATH" ]; then
    echo "Error: Cannot read certificate file $CERT_PATH. Check permissions."
    echo "Current permissions: $(ls -l $CERT_PATH)"
    echo "Directory permissions: $(ls -ld /etc/letsencrypt/live/xanalyzer.wizwam.com/)"
    return 1
  fi
  if ! file_exists "$KEY_PATH"; then
    echo "Error: Key symbolic link $KEY_PATH not found."
    return 1
  fi
  if ! [ -r "$KEY_PATH" ]; then
    echo "Warning: Cannot read private key file $KEY_PATH. May not be needed if Nginx handles it."
    echo "Current permissions: $(ls -l $KEY_PATH)"
    echo "Directory permissions: $(ls -ld /etc/letsencrypt/live/xanalyzer.wizwam.com/)"
  fi

  echo "All dependencies appear to be installed."
  return 0
}

# Run the check_dependencies function
check_dependencies

# Exit with the correct code
if [ $? -eq 0 ]; then
  deactivate
fi
exit $?