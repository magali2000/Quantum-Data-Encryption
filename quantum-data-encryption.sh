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

# Function to check if file is already encrypted
check_file_encrypted() {
  if [[ $1 == *.enc ]]; then
    echo "File $1 is already encrypted."
    return 1
  fi
}

# Function to check if file is already decrypted
check_file_decrypted() {
  if [[ $1 != *.enc ]]; then
    echo "File $1 is already decrypted."
    return 1
  fi
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

# Function to get password
get_password() {
  echo "Do you want to use a password from a file? (y/n): "
  read use_file
  if [[ "$use_file" == "y" || "$use_file" == "Y" ]]; then
    echo "Enter the path to the password file: "
    read password_file
    check_file_exists "$password_file"
    password=$(cat "$password_file")
  else
    for i in {1..3}
    do
      read -sp "Enter the password: " password
      if check_password_strength "$password"; then
        break
      elif [ $i -eq 3 ]; then
        echo "Failed to provide a strong password in 3 attempts. Exiting."
        exit 1
      fi
    done
  fi
}

# Function to encrypt file
encrypt_file() {
  check_file_exists "$1"
  check_file_encrypted "$1"
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
  check_file_decrypted "$1"
  for i in {1..3}
  do
    openssl aes-256-cbc -d -a -in "$1" -out "${1%.enc}" -pass pass:"$2" 2>error.log
    if [ $? -eq 0 ]; then
      echo "$(date): Decrypted file $1." >> log.txt
      read -p "Do you want to delete the encrypted file? (y/n): " del
      if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm "$1"
        echo "$(date): Deleted encrypted file $1." >> log.txt
      fi
      return 0
    else
      if grep -q "bad decrypt" error.log; then
        echo "Incorrect password. Please try again."
      else
        echo "Decryption failed due to other reasons. Please check the error.log file for more details."
        exit 1
      fi
    fi
  done
  echo "Failed to decrypt file after 3 attempts. Exiting."
  exit 1
}

# Check if openssl is installed
check_openssl_installed

# User input for operation choice
echo "What operation would you like to perform? (encrypt/decrypt): "
read operation

case $operation in
  "encrypt")
    echo "Enter the file paths to encrypt (separated by space): "
    read -a file_paths

    check_file_exists "${file_paths[@]}"

    for file_path in "${file_paths[@]}"
    do
      get_password
      encrypt_file "$file_path" "$password"
      echo "File $file_path encrypted successfully."
    done
    ;;
  "decrypt")
    echo "Enter the encrypted file paths to decrypt (separated by space): "
    read -a enc_file_paths

    check_file_exists "${enc_file_paths[@]}"

    for enc_file_path in "${enc_file_paths[@]}"
    do
      get_password
      if decrypt_file "$enc_file_path" "$password"; then
        echo "File $enc_file_path decrypted successfully."
      else
        echo "Failed to decrypt file after 3 attempts. Exiting."
        exit 1
      fi
    done
    ;;
  *)
    echo "Invalid operation. Please enter either 'encrypt' or 'decrypt'."
    exit 1
    ;;
esac
