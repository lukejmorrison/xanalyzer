require('dotenv').config();
const express = require('express');
const https = require('https');
const fs = require('fs');
const axios = require('axios');
const session = require('express-session');
const crypto = require('crypto');
const winston = require('winston');
const app = express();

// Configure winston logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.printf(({ timestamp, level, message }) => {
            return `${timestamp} [${level.toUpperCase()}]: ${message}`;
        })
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'app.log' }) // Changed to app.log
    ]
});


// Log server start
logger.info('Starting xanalyzer server...');

// Session middleware setup (fixed secret option)
app.use(session({
    secret: process.env.SESSION_SECRET || 'fallback-secret-here', // Fallback if .env misses it
    resave: false,
    saveUninitialized: false,
    cookie: { secure: true, httpOnly: true } // Secure for HTTPS
}));

// OAuth configuration
const clientId = process.env.CLIENT_ID;
const redirectUri = 'https://xanalyzer.wizwam.com/callback';

// Generate PKCE code verifier
function generateCodeVerifier() {
    return crypto.randomBytes(32).toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');
}

// Generate PKCE code challenge
function generateCodeChallenge(verifier) {
    return crypto.createHash('sha256')
        .update(verifier)
        .digest('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');
}

// Shared HTML template function
const htmlTemplate = (title, content) => `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title}</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f4f4f4; }
            h1 { color: #333; }
            p { color: #666; }
            a { color: #007bff; text-decoration: none; }
            a:hover { text-decoration: underline; }
        </style>
    </head>
    <body>
        ${content}
    </body>
    </html>
`;

// Login route to initiate OAuth
app.get('/login', (req, res) => {
    logger.info('Received request to /login');
    const codeVerifier = generateCodeVerifier();
    const codeChallenge = generateCodeChallenge(codeVerifier);
    req.session.codeVerifier = codeVerifier;

    const authUrl = `https://twitter.com/i/oauth2/authorize?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&code_challenge=${codeChallenge}&code_challenge_method=S256`;
    logger.info(`Redirecting to X authorization URL: ${authUrl}`);
    res.redirect(authUrl);
});

// Callback route for OAuth token exchange
app.get('/callback', async (req, res) => {
    logger.info('Received request to /callback');
    const code = req.query.code;
    const codeVerifier = req.session.codeVerifier;

    if (!code || !codeVerifier) {
        logger.error('Missing code or codeVerifier in /callback');
        res.send(htmlTemplate('Authentication Callback', `
            <h1>Authentication in Progress</h1>
            <p>Looks like you wandered here without the right keys. Let’s get you started!</p>
            <p><a href="/login">Start Authentication</a></p>
            <script>console.log('Missing code or codeVerifier');</script>
        `));
    } else {
        try {
            logger.info('Exchanging authorization code for access token...');
            const tokenResponse = await axios.post('https://api.x.com/oauth2/token', {
                grant_type: 'authorization_code',
                code: code,
                redirect_uri: redirectUri,
                client_id: clientId,
                code_verifier: codeVerifier
            }, {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            });

            const { access_token, refresh_token } = tokenResponse.data;
            req.session.accessToken = access_token;
            req.session.refreshToken = refresh_token;
            logger.info('Successfully exchanged authorization code for access token.');
            res.redirect('/');
        } catch (error) {
            logger.error(`Token exchange failed: ${error.response?.data || error.message}`);
            res.status(500).send(htmlTemplate('Authentication Error', `
                <h1>Oops, Something Went Wrong</h1>
                <p>Authentication hit a snag. Try again?</p>
                <p><a href="/login">Retry Login</a></p>
            `));
        }
    }
});

// New route to get the access token
app.get('/get_token', (req, res) => {
    logger.info('Received request to /get_token');
    if (req.session.accessToken) {
        logger.info('Returning access token.');
        res.json({ access_token: req.session.accessToken });
    } else {
        logger.warn('No access token found in session.');
        res.status(401).send(htmlTemplate('Not Authenticated', `
            <h1>Not Logged In</h1>
            <p>You need to authenticate to get a token.</p>
            <p><a href="/login">Login</a></p>
        `));
    }
});

// Main page
app.get('/', (req, res) => {
    logger.info('Received request to /');
    if (req.session.accessToken) {
        logger.info('User is authenticated.');
        res.send(htmlTemplate('XAnalyzer', `
            <h1>Welcome to XAnalyzer!</h1>
            <p>You’re in! Ready to analyze some X magic.</p>
            <p>Grab your token at <a href="/get_token">/get_token</a>.</p>
        `));
    } else {
        logger.info('User is not authenticated.');
        res.send(htmlTemplate('XAnalyzer', `
            <h1>Welcome to XAnalyzer!</h1>
            <p>Your gateway to X analysis awaits.</p>
            <p><a href="/login">Login with X</a> to get started.</p>
        `));
    }
});

// Catch-all for undefined routes
app.use((req, res) => {
    logger.warn(`404 - Route not found: ${req.originalUrl}`);
    res.status(404).send(htmlTemplate('404 - Not Found', `
        <h1>404 - Lost in the X Void</h1>
        <p>Nothing here, traveler! Head back to <a href="/">home</a>.</p>
    `));
});

// Load certificate and key
const certPath = '/etc/letsencrypt/live/xanalyzer.wizwam.com/fullchain.pem';
const keyPath = '/etc/letsencrypt/live/xanalyzer.wizwam.com/privkey.pem';

const httpsOptions = {
    cert: fs.readFileSync(certPath),
    key: fs.readFileSync(keyPath),
};

// Create HTTPS server
const httpsServer = https.createServer(httpsOptions, app);

// Start the HTTPS server on 443
const httpsPort = 443;
httpsServer.listen(httpsPort, () => {
    logger.info(`HTTPS server listening on port ${httpsPort}`);
    console.log(`HTTPS server listening on port ${httpsPort}`);
});