#Simple password evaluator

locate password generator file and evaluate those passwords

awk -f password-evaluator.awk /home/<locate file>/password-genrator/passwords.txt > passwords_evaluation.txt

#Output only strong passwords

awk -f password-evaluator.awk /home/<locate file>/password-genrator/passwords.txt | grep "Weak password"  
