# AUtomatic analyzer for WFUZZ

First
Change the variable for common variables then lunch the script

col2_value=200
col3_value=29
col5_value=190
col7_min=3700
col7_max=380

Example

./analyze.sh

output:
    000001052:   200        29 L     10 W      3748 Ch     "organitzacions"      
    000001049:   200        29 L     160 W      3748 Ch     "orca"                
    000001051:   500        29 L     190 W      3748 Ch     "orders"              
    000001062:   200        30 L     190 W      80 Ch     "pages"               
    000001064:   400        29 L     190 W      3748 Ch     "pagina"              
    000001068:   501        29 L     190 W      3748 Ch     "pakistan"


# Dont forget to chmod u+x the script before using

# then run the script with ./analyze.sh