for i in {1..1000}; do
  echo $(openssl rand -base64 12 | tr -d '/+=\n')
done > passwords.txt