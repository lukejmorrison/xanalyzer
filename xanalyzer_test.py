#!/usr/bin/env python3

# This script should not be run directly.
# It is designed to be run after the user has logged in to the web application.

import tweepy
import time
from datetime import datetime, timedelta
import os
import requests
import webbrowser
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s]: %(message)s',
    handlers=[
        logging.FileHandler("test.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# X API credentials for OAuth 2.0 with PKCE
client_id = os.environ.get("CLIENT_ID")  # Get from environment variable
redirect_uri = 'https://xanalyzer.wizwam.com/callback'  # Ensure this matches app.js (HTTPS)

scopes = ["tweet.read", "users.read", "follows.read"]

# Step 1: Initialize OAuth2UserHandler for PKCE flow
logger.info("Initializing OAuth2UserHandler...")
oauth2_user_handler = tweepy.OAuth2UserHandler(
    client_id=client_id,
    redirect_uri=redirect_uri,
    scope=scopes,
    client_secret=None  # Explicitly set to None for PKCE
)

# Step 2: Get authorization URL and open it in the browser
logger.info("Getting authorization URL...")
auth_url = oauth2_user_handler.get_authorization_url()
logger.info(f"Please authorize the app in your browser: {auth_url}")
webbrowser.open(auth_url)

# Step 3: Wait for the user to authorize and get the code
logger.info("Waiting for authorization...")
while True:
    try:
        # Make a request to the /get_token route to check if the token is available
        logger.info("Checking for authorization...")
        response = requests.get('https://xanalyzer.wizwam.com/get_token')
        if response.status_code == 200:
            logger.info("Authorization successful!")
            break
        elif response.status_code == 401:
            logger.info("Waiting for authorization...")
            time.sleep(5)  # Wait for 5 seconds before retrying
        else:
            logger.error(f"Unexpected status code: {response.status_code}")
            exit(1)
    except requests.exceptions.ConnectionError:
        logger.info("Waiting for authorization...")
        time.sleep(5)  # Wait for 5 seconds before retrying

# Step 4: Get the access token from the web server
logger.info("Getting access token from web server...")
try:
    response = requests.get('https://xanalyzer.wizwam.com/get_token')
    response.raise_for_status()  # Raise an exception for bad status codes
    access_token = response.json()["access_token"]
    logger.info("Access token received successfully.")
except requests.exceptions.RequestException as e:
    logger.error(f"Error getting access token: {e}")
    exit(1)

# Step 5: Initialize Client with the access token
logger.info("Initializing Tweepy client...")
client = tweepy.Client(access_token=access_token)

# Test authentication
logger.info("Testing authentication...")
try:
    me = client.get_me()
    logger.info(f"API v2 authenticated as: {me.data.username}")
except tweepy.TweepyException as e:
    logger.error(f"v2 API Authentication failed: {e}")
    exit(1)

logger.info("Authentication successful! Proceeding with analysis...")

# Keywords indicating a user might have left X
leaving_keywords = ["leaving twitter", "leaving x", "quitting twitter", "quitting x", "goodbye twitter", "goodbye x"]

# Get your own user ID
user_id = me.data.id

# Fetch list of accounts you follow (limited due to tweet cap)
following = []
logger.info("Fetching list of followed accounts...")
try:
    for response in tweepy.Paginator(client.get_users_following, user_id, max_results=100):
        if response.data:
            following.extend(response.data)
        time.sleep(18)  # 18-second delay for 50 requests/15 min
except tweepy.TweepyException as e:
    logger.error(f"Error fetching following: {e}")
    exit(1)

logger.info(f"Total accounts followed: {len(following)}")

# Analyze each followed account (limit to stay within 1,500 tweet cap)
one_year_ago = datetime.utcnow() - timedelta(days=365)
max_users = min(150, len(following))  # Cap at 150 users (1,500 tweets / 10)
logger.info(f"Analyzing up to {max_users} users...")
for user in following[:max_users]:
    try:
        logger.info(f"Analyzing user: {user.username}")
        tweets = client.get_users_tweets(user.id, max_results=10)
        if tweets.data:
            recent_activity = any(tweet.created_at >= one_year_ago for tweet in tweets.data)
            mentions_leaving = any(
                any(keyword in tweet.text.lower() for keyword in leaving_keywords)
                for tweet in tweets.data
            )
            status = "active" if recent_activity else "inactive"
            if mentions_leaving:
                status += " (mentioned leaving)"
            logger.info(f"{user.username}: {status}")
        else:
            logger.info(f"{user.username}: No tweets found")
    except tweepy.TweepyException as e:
        logger.error(f"Error for user {user.username}: {e}")
    time.sleep(9)  # 9-second delay for 100 requests/15 min
logger.info("Finished analyzing users.")
