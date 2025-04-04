# xanalyzer

xanalyzer is a Node.js application that analyzes the X (formerly Twitter) accounts you follow, determining their activity status and checking for mentions of leaving the platform. It uses OAuth 2.0 with PKCE for secure X API authentication and integrates Python scripts for analysis via Tweepy. The server runs directly on port 443 with HTTPS, secured by Certbot certificates.

## Features

- **X Account Analysis**: Evaluates activity and "leaving" mentions for accounts you follow.
- **OAuth 2.0 with PKCE**: Secure authentication flow for X API access.
- **Direct HTTPS**: Runs on port 443 with Certbot-managed certificates—no reverse proxy required.
- **Tailscale Integration**: Optional secure routing via Tailscale App Connector.
- **GitOps**: Manages Tailscale ACLs through GitHub Actions.
- **PM2**: Optional process manager for running the server persistently.

## Project Structure

- `/src/app.js`: Core Node.js server handling OAuth and HTTPS on port 443.
- `/src/xanalyzer_test.py`: Python script for X API analysis.
- `/backup/xanalyzer_test_v2.py`: Alternative analysis script.
- `/tailscale/acls.json`: Tailscale ACL configuration for Git Sulph.
- `/start_app.sh`: Script to launch the app with PM2 (optional).

## Prerequisites

- **X Developer Account**: Configure an app with OAuth 2.0 and PKCE.
  - **Redirect URI**: `https://xanalyzer.yourdomain.com/callback` (replace with your domain).
  - **Scopes**: `tweet.read`, `users.read`, `follows.read`.
- **Domain & Certbot**: A domain pointing to your VM’s public IP, with Certbot installed.
- **Node.js & npm**: Required for the server.
- **Python 3 & pip**: Needed for analysis scripts.
- **Tailscale**: Optional for secure access and routing.
- **GitHub Account**: For GitOps management of Tailscale ACLs.
- **Ubuntu VM**: Host for deploying the application.

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/lukejmorrison/xanalyzer.git
   cd xanalyzer
   ```

2. **Run the Setup Script**:
   ```bash
   ./setup.sh
   ```
   This script:
   - Verifies Node.js, npm, and Python 3 are installed.
   - Creates a Python virtual environment at `/opt/xanalyzer/src/.venv/`.
   - Installs Node.js dependencies: `express`, `axios`, `express-session`, `dotenv`, `winston`.
   - Installs Python dependencies: `tweepy`, `requests`.
   - Sets up essential files: `.env`, `app.log`, `package.json`, `app.js`.

3. **Configure Environment Variables**:
   - Edit `/opt/xanalyzer/src/.env`:
     ```
     CLIENT_ID=your_x_client_id
     SESSION_SECRET=generate_with_openssl_rand_-base64_32
     PORT=443
     ```

4. **Set Up Certbot**:
   - Install Certbot:
     ```bash
     sudo apt install certbot -y
     ```
   - Obtain certificates:
     ```bash
     sudo certbot certonly --standalone -d xanalyzer.yourdomain.com
     ```
   - Certificates are typically stored at `/etc/letsencrypt/live/xanalyzer.yourdomain.com/`. Update `app.js` with these paths if necessary.

5. **Configure Tailscale (Optional)**:
   - Generate a reusable auth key in the Tailscale admin panel with the tag `tag:xanalyzer-connector`.
   - Add `TAILSCALE_AUTHKEY` as a GitHub Actions secret in your repository.
   - Copy `/opt/xanalyzer/tailscale/acls.json` to your Tailscale ACL configuration.
   - Set up a Tailscale App Connector for your subdomain if desired.

6. **Update Redirect URI**:
   - In the X Developer Portal, set the redirect URI to `https://xanalyzer.yourdomain.com/callback`.
   - In `/src/app.js`, ensure:
     ```javascript
     const redirectUri = 'https://xanalyzer.yourdomain.com/callback';
     ```
   - In Python scripts (`xanalyzer_test.py` and `xanalyzer_test_v2.py`):
     ```python
     redirect_uri = 'https://xanalyzer.yourdomain.com/callback'
     ```

7. **Commit Changes**:
   ```bash
   git add .
   git commit -m "Initial setup with HTTPS on port 443"
   git push -u origin main
   ```

## Deployment on Ubuntu VM

1. **Install Prerequisites**:
   - Update packages:
     ```bash
     sudo apt update
     ```
   - Install required tools:
     ```bash
     sudo apt install git nodejs python3 python3-pip openssl certbot -y
     curl -fsSL https://tailscale.com/install.sh | sh
     ```

2. **Clone and Set Up**:
   ```bash
   sudo mkdir /opt/xanalyzer
   sudo chown $USER:$USER /opt/xanalyzer
   cd /opt/xanalyzer
   git clone https://github.com/lukejmorrison/xanalyzer.git .
   ./setup.sh
   ```

3. **Configure `.env`**:
   - Set `CLIENT_ID`, `SESSION_SECRET`, and `PORT=443` in `/opt/xanalyzer/src/.env`.

4. **Obtain Certificates**:
   ```bash
   sudo certbot certonly --standalone -d xanalyzer.yourdomain.com
   ```

5. **Start the App**:
   - Run directly (requires sudo for port 443):
     ```bash
     sudo node /opt/xanalyzer/src/app.js &
     ```
   - Or use PM2 for persistence:
     ```bash
     sudo npm install -g pm2
     sudo pm2 start /opt/xanalyzer/src/app.js --name xanalyzer
     sudo pm2 save
     sudo pm2 startup
     ```

6. **Tailscale (Optional)**:
   - Authenticate the VM:
     ```bash
     sudo tailscale up --authkey=YOUR_AUTH_KEY
     ```
   - Configure as needed for routing.

## Running the Analysis

1. **Activate Virtual Environment**:
   ```bash
   source /opt/xanalyzer/src/.venv/bin/activate
   ```

2. **Run Analysis**:
   - Primary script:
     ```bash
     cd /opt/xanalyzer/src/
     python3 xanalyzer_test.py
     ```
   - Alternative script:
     ```bash
     cd /opt/xanalyzer/backup/
     python3 xanalyzer_test_v2.py
     ```

## Contributing

Pull requests are welcome! For significant changes, please open an issue to discuss first.

## License

MIT