# Just a translator for popular commands in linux to powershell

Sometimes you dont want to run commands in kali linux


## Example

    ./basictranslator.sh curl ipinfo.io/52.156.12.167

    output : Invoke-RestMethod -Uri ipinfo.io/52.156.12.167trans

## In scripts

*curl
*ls
*df
*ping


# Dont forget to chmod u+x the script before using