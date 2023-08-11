BEGIN { FS = "" }  # Set field separator to empty string (each character)
{
#NF = umber of fields in the current input record
for (i = 1; i <= NF; i++) {
if ($i ~ /[A-Z]/) upper = 1;
if ($i ~ /[a-z]/) lower = 1;
if ($i ~ /[0-9]/) digit = 1;
#if ($i ~ /[!@#$%^&*()_+{};:"<>,.?]/) special = 1;
if ( $i ~ /[!@#$%^&*()_+{};:"<>,.?]/ ) special = 1;
}
++cnt
# Analyze patterns and print password
if (upper && lower && digit && special) {
print cnt,$0, "- Strong password";
} else if (upper && lower && digit) {
print cnt,$0, "- Moderately strong password";
} else {
print cnt,$0, "- Weak password";
}

# Reset flags for the next password
upper = lower = digit = special = 0;
}

