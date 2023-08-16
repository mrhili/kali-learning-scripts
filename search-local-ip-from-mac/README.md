# simple search of ip address in youre local network if you have just the mac address and will ping it if located

Example

./search.sh 20:64:32:3F:B1:A9

output:
    64 bytes from 192.168.11.186: icmp_seq=1 ttl=64 time=70.4 ms


# Dont forget to chmod u+x the script before using

# then run the script with ./search.sh <youre mac adress>