# xanalyzer

xanalyzer is a project that analyzes the X (formerly Twitter) accounts you follow to determine if they are still active or if they have mentioned leaving the platform. It consists of a Node.js server that handles the OAuth 2.0 authentication flow with X and Python scripts that perform the analysis.

## Features

*   **X Account Analysis:** Analyzes the X accounts you follow.
*   **Activity Detection:** Determines if followed accounts are active or inactive based on recent tweets.
*   **Leaving Detection:** Detects if followed accounts have mentioned leaving X.
*   **OAuth 2.0:** Uses OAuth 2.0 with PKCE for secure authentication with X.
*   **Node.js Server:** Provides a web server to handle the OAuth 2.0 flow.
*   **Python Scripts:** Uses Python scripts to interact with the X API and perform the analysis.
*   **Tailscale App Connector:** Uses a Tailscale App Connector to route traffic to the server.
*   **GitOps:** Uses GitOps to manage the Tailscale ACLs.
*   **PM2:** Uses PM2 to manage the server.

## Project Structure


## Prerequisites

*   **X Developer Account:** You need an X Developer account and an app configured with OAuth 2.0 with PKCE.
    *   **Redirect URI:** `https://xanalyzer.yourtailnet.ts.net:7042/callback` (replace `xanalyzer.yourtailnet.ts.net` with your Tailscale subdomain).
    *   **Scopes:** `tweet.read`, `users.read`, `follows.read`.
*   **Node.js and npm:** Make sure Node.js and npm are installed.
*   **Python 3:** Make sure Python 3 is installed.
*   **Tailscale:** Install the Tailscale client on the machine where you'll run the server.
*   **GitHub Account:** You need a GitHub account to use the GitHub Actions workflow.
* **Ubuntu VM:** You need an Ubuntu VM to deploy the project.

## Installation

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/lukejmorrison/xanalyzer.git
    cd xanalyzer
    ```

2.  **Run the Setup Script:**
    ```bash
    ./setup.sh
    ```
    This script will:
    *   Check for Node.js, npm, and Python 3.
    *   Create a Python virtual environment in `/opt/xanalyzer/src/.venv/`.
    *   Install the required Node.js dependencies (`express`, `axios`, `express-session`, `dotenv`, `winston`).
    *   Install the required Python dependencies (`tweepy`, `requests`) in the virtual environment.
    * Create the `.env` file in `/opt/xanalyzer/src/`.
    * Create the `test.log` file in `/opt/xanalyzer/src/`.
    * Create the `package.json` file in `/opt/xanalyzer/src/`.
    * Create the `app.js` file in `/opt/xanalyzer/src/`.
    * Create the `ecosystem.config.js` file in `/opt/xanalyzer/`.
    * Create the `start_app.sh` file in `/opt/xanalyzer/`.
    * Create the `xanalyzer_test.py` file in `/opt/xanalyzer/src/`.
    * Create the `.gitignore` file in `/opt/xanalyzer/`.

3.  **Configure Environment Variables:**
    *   Edit the `/opt/xanalyzer/src/.env` file and set the following variables:
        *   `CLIENT_ID`: Your X app's Client ID.
        *   `SESSION_SECRET`: A strong, random string (you can generate one using `openssl rand -base64 32`).
        * `PORT`: The port the server will run on (default: 7042).

4. **Create a Tailscale Auth Key:**
    *   Go to your Tailscale admin panel (https://login.tailscale.com/admin/).
    *   Navigate to "Settings" -> "Auth keys".
    *   Click "Generate auth key".
    *   **Reusable:** Check the "Reusable" box.
    *   **Ephemeral:** Uncheck the "Ephemeral" box.
    *   **Tags:** Add the tag `tag:xanalyzer-connector`.
    *   **Expiration:** Set an expiration date if you want.
    *   Click "Generate key".
    *   Copy the generated key.

5.  **Configure GitHub Secrets:**
    *   Go to your GitHub repository.
    *   Go to "Settings" -> "Secrets and variables" -> "Actions".
    *   Click "New repository secret".
    *   **Name:** `TAILSCALE_AUTHKEY`
    *   **Secret:** Paste the Tailscale auth key you copied.
    *   Click "Add secret".

6. **Configure the Tailscale App Connector:**
    *   **Tailscale Admin Panel:** Go to your Tailscale admin panel (https://login.tailscale.com/admin/).
    *   **App Connectors:** Navigate to the "App connectors" section.
    *   **Create Connector:** Click "Create connector".
    *   **Connector Name:** Give your connector a descriptive name (e.g., `xanalyzer-connector`).
    *   **Connector Type:** Select "TCP".
    *   **Local Address:**
        *   **Address:** `127.0.0.1` (or `localhost`)
        *   **Port:** `7042`
    *   **Tailnet Address:**
        *   **Subdomain:** Choose a subdomain for your app (e.g., `xanalyzer`).
        *   **Port:** `7042`
    *   **Save:** Save the connector configuration.
    * **Enable the connector:** Enable the connector.

7. **Run the Connector:**
    *   **Tailscale CLI:** On the machine where your `xanalyzer` server is running, use the Tailscale CLI to run the connector:
        ```bash
        tailscale serve tcp --accept-routes 7042
        ```
        or
        ```bash
        tailscale serve xanalyzer-connector
        ```

8.  **Update the Redirect URI in Your X App:**
    *   **X Developer Portal:** Go to your X Developer Portal and edit your app's settings.
    *   **Redirect URI:** Change the "Redirect URI" to use your Tailscale subdomain:
        ```
        https://xanalyzer.yourtailnet.ts.net:7042/callback
        ```

9.  **Update the Redirect URI in `app.js` and `xanalyzer_test_v2.py`:**
    *   **`/opt/xanalyzer/src/app.js`:**
        ```javascript
        const redirectUri = 'https://xanalyzer.yourtailnet.ts.net:7042/callback';
        ```
    *   **`/opt/xanalyzer/backup/xanalyzer_test_v2.py`:**
        ```python
        redirect_uri = 'https://xanalyzer.yourtailnet.ts.net:7042/callback'
        ```
    * **`/opt/xanalyzer/src/xanalyzer_test.py`:**
        ```python
        redirect_uri = 'https://xanalyzer.yourtailnet.ts.net:7042/callback'
        ```

10. **Apply the Tailscale ACLs:**
    *   Copy the content of `/opt/xanalyzer/tailscale/acls.json` to your Tailscale ACLs.
    * **Tag the connector:** Tag the connector with `tag:xanalyzer-connector` in the Tailscale admin panel.

11. **Commit the changes:**
    ```bash
    git add .
    git commit -m "Initial commit"
    git push -u origin main
    ```

## Deployment on Ubuntu VM

These instructions are for deploying `xanalyzer` on an Ubuntu VM.

1.  **Install Prerequisites:**
    *   **Update Package List:**
        ```bash
        sudo apt update
        ```
    *   **Install Git:**
        ```bash
        sudo apt install git -y
        ```
    *   **Install Node.js and npm:**
        ```bash
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install nodejs -y
        ```
    *   **Install Python 3 and pip:**
        ```bash
        sudo apt install python3 python3-pip -y
        ```
    * **Install openssl:**
        ```bash
        sudo apt install openssl -y
        ```
    * **Install pm2:**
        ```bash
        sudo npm install -g pm2
        ```
    * **Install tailscale:**
        ```bash
        curl -fsSL https://tailscale.com/install.sh | sh
        ```

2.  **Clone the Repository:**
    ```bash
    sudo mkdir /opt/xanalyzer
    sudo chown $USER:$USER /opt/xanalyzer
    cd /opt/xanalyzer
    git clone https://github.com/lukejmorrison/xanalyzer.git .
    ```

3.  **Run the Setup Script:**
    ```bash
    ./setup.sh
    ```

4.  **Configure Environment Variables:**
    *   Edit the `/opt/xanalyzer/src/.env` file and set the following variables:
        *   `CLIENT_ID`: Your X app's Client ID.
        *   `SESSION_SECRET`: A strong, random string (you can generate one using `openssl rand -base64 32`).
        * `PORT`: The port the server will run on (default: 7042).

5. **Configure the Tailscale App Connector:**
    *   **Tailscale Admin Panel:** Go to your Tailscale admin panel (https://login.tailscale.com/admin/).
    *   **App Connectors:** Navigate to the "App connectors" section.
    *   **Create Connector:** Click "Create connector".
    *   **Connector Name:** Give your connector a descriptive name (e.g., `xanalyzer-connector`).
    *   **Connector Type:** Select "TCP".
    *   **Local Address:**
        *   **Address:** `127.0.0.1` (or `localhost`)
        *   **Port:** `7042`
    *   **Tailnet Address:**
        *   **Subdomain:** Choose a subdomain for your app (e.g., `xanalyzer`).
        *   **Port:** `7042`
    *   **Save:** Save the connector configuration.
    * **Enable the connector:** Enable the connector.

6. **Run the Connector:**
    *   **Tailscale CLI:** On the machine where your `xanalyzer` server is running, use the Tailscale CLI to run the connector:
        ```bash
        sudo tailscale up
        sudo tailscale serve tcp --accept-routes 7042
        ```
        or
        ```bash
        sudo tailscale up
        sudo tailscale serve xanalyzer-connector
        ```

7.  **Update the Redirect URI in Your X App:**
    *   **X Developer Portal:** Go to your X Developer Portal and edit your app's settings.
    *   **Redirect URI:** Change the "Redirect URI" to use your Tailscale subdomain:
        ```
        https://xanalyzer.yourtailnet.ts.net:7042/callback
        ```

8.  **Update the Redirect URI in `app.js` and `xanalyzer_test_v2.py`:**
    *   **`/opt/xanalyzer/src/app.js`:**
        ```javascript
        const redirectUri = 'https://xanalyzer.yourtailnet.ts.net:7042/callback';
        ```
    *   **`/opt/xanalyzer/backup/xanalyzer_test_v2.py`:**
        ```python
        redirect_uri = 'https://xanalyzer.yourtailnet.ts.net:7042/callback'
        ```
    * **`/opt/xanalyzer/src/xanalyzer_test.py`:**
        ```python
        redirect_uri = 'https://xanalyzer.yourtailnet.ts.net:7042/callback'
        ```

9. **Apply the Tailscale ACLs:**
    *   Copy the content of `/opt/xanalyzer/tailscale/acls.json` to your Tailscale ACLs.
    * **Tag the connector:** Tag the connector with `tag:xanalyzer-connector` in the Tailscale admin panel.

10. **Start the server:**
    ```bash
    ./start_app.sh
    ```

## Running the Analysis

1.  **Activate the Virtual Environment:**
    ```bash
    source /opt/xanalyzer/src/.venv/bin/activate
    ```

2.  **Run the Analysis Script:**
    ```bash
    cd /opt/xanalyzer/src/
    python3 xanalyzer_test.py
    ```
    or
    ```bash
    cd /opt/xanalyzer/backup/
    python3 xanalyzer_test_v2.py
    ```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

MIT
