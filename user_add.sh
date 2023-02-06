#!/bin/bash

# Prompt the user for a username
read -p "Enter a username: " username

# Check if the username contains a dash
if ! echo "$username" | grep -q "-"; then
  echo "Username must contain a dash"
  exit 1
fi

# Check if the username is already in use
if id "$username" > /dev/null 2>&1; then
  echo "Username is already in use"
  exit 1
fi

# Generate a random alphanumeric password with special characters
password=$(< /dev/urandom tr -dc 'A-Za-z0-9#&?@' | head -c${1:-10})
# Create the user with the random password
useradd -m  "$username"	 > /dev/null
echo "$username:$password" | chpasswd
chsh -s /bin/bash "$username"
# Print the username and password to the screen
echo -e "\n"
echo "==========================================================="
echo -e "\033[0m"
echo -e  "\033[1m\033[32mUsername: $username\033[1m\033[32m"
echo -e "\033[1m\033[32mPassword: $password\033[1m\033[32m"
echo -e "\033[0m"
echo "==========================================================="

su -c 'ssh-keygen -f ~/.ssh/id_rsa -N "" -q'  $username > /dev/null
echo -e "\n"
echo "Please copy the following public key of the user and paste in the auotherized_keys of the remote server"

echo -e "\033[1m\033[32m"
su -c "cat /home/$username/.ssh/id_rsa.pub" $username
echo -e "\033[0m"

