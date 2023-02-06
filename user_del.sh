#!/bin/bash
# Script to delete the username
# Prompt the user for a username
read -p "Enter the username to delete: " username

# Delete the user
userdel -r "$username"

# Check if the user was deleted successfully
if [ $? -eq 0 ]; then
  echo "User $username was deleted successfully"
else
  echo "Error deleting user $username"
fi

