#!/bin/bash

# Function to check if openssl is installed
check_openssl_installed() {
  if ! command -v openssl &> /dev/null
  then
    echo "openssl could not be found. Please install openssl and try again."
    exit 1
  fi
}

# Function to check if file exists
check_file_exists() {
  for file in "$@"
  do
    if [ ! -f "$file" ]; then
      echo "File $file does not exist."
      exit 1
    fi
  done
}

# Function to check password strength
check_password_strength() {
  if [[ ${#1} -ge 8 && "$1" == *[A-Z]* && "$1" == *[a-z]* && "$1" == *[0-9]* && "$1" == *[@#\$%^\&*()_+]* ]]
  then
    echo "Strong password"
  else
    echo "Weak password. Password should be at least 8 characters long, with uppercase, lowercase, number and special character."
    return 1
  fi
}

# Function to check command status
check_command_status() {
  if [ $? -ne 0 ]; then
    echo "$1 failed."
    exit 1
  fi
}

# Function to encrypt file
encrypt_file() {
  check_file_exists "$1"
  openssl aes-256-cbc -a -salt -in "$1" -out "$1.enc" -pass pass:"$2" 2>/dev/null
  check_command_status "File encryption"
  echo "$(date): Encrypted file $1." >> log.txt
  read -p "Do you want to delete the original file? (y/n): " del
  if [[ "$del" == "y" || "$del" == "Y" ]]; then
    rm "$1"
    echo "$(date): Deleted original file $1." >> log.txt
  fi
}

# Function to decrypt file
decrypt_file() {
  check_file_exists "$1"
  for i in {1..3}
  do
    openssl aes-256-cbc -d -a -in "$1" -out "${1%.enc}" -pass pass:"$2" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "$(date): Decrypted file $1." >> log.txt
      read -p "Do you want to delete the encrypted file? (y/n): " del
      if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm "$1"
        echo "$(date): Deleted encrypted file $1." >> log.txt
      fi
      return 0
    else
      echo "Incorrect password. Please try again."
    fi
  done
  echo "Failed to decrypt file after 3 attempts. Exiting."
  exit 1
}

# Check if openssl is installed
check_openssl_installed

# User input for file encryption and decryption
echo "Enter the file paths to encrypt (separated by space): "
read -a file_paths

check_file_exists "${file_paths[@]}"

for file_path in "${file_paths[@]}"
do
  for i in {1..3}
  do
    read -sp "Enter the password for $file_path: " password
    if check_password_strength "$password"; then
      encrypt_file "$file_path" "$password"
      echo "File $file_path encrypted successfully."
      break
    elif [ $i -eq 3 ]; then
      echo "Failed to provide a strong password in 3 attempts. Exiting."
      exit 1
    fi
  done
done

echo "Enter the encrypted file paths to decrypt (separated by space): "
read -a enc_file_paths

check_file_exists "${enc_file_paths[@]}"

for enc_file_path in "${enc_file_paths[@]}"
do
  for i in {1..3}
  do
    read -sp "Enter the password for $enc_file_path: " password
    if decrypt_file "$enc_file_path" "$password"; then
      echo "File $enc_file_path decrypted successfully."
      break
    elif [ $i -eq 3 ]; then
      echo "Failed to decrypt file after 3 attempts. Exiting."
      exit 1
    fi
  done
done