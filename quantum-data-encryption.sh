#!/bin/bash

# Function to encrypt data
encrypt_data() {
  echo -n "$1" | openssl aes-256-cbc -a -salt -pass pass:"$2" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Encryption failed."
    exit 1
  fi
}

# Function to decrypt data
decrypt_data() {
  echo -n "$1" | openssl aes-256-cbc -d -a -pass pass:"$2" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Decryption failed."
    exit 1
  fi
}

# Function to encrypt file
encrypt_file() {
  openssl aes-256-cbc -a -salt -in "$1" -out "$1.enc" -pass pass:"$2" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "File encryption failed."
    exit 1
  fi
}

# Function to decrypt file
decrypt_file() {
  openssl aes-256-cbc -d -a -in "$1" -out "${1%.enc}" -pass pass:"$2" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "File decryption failed."
    exit 1
  fi
}

# User input for password and data
read -p "Enter the password: " password
read -p "Enter the data: " original_data

# Test the functions
encrypted_data=$(encrypt_data "$original_data" "$password")
echo "Encrypted data: $encrypted_data"

decrypted_data=$(decrypt_data "$encrypted_data" "$password")
echo "Decrypted data: $decrypted_data"

# User input for file encryption and decryption
read -p "Enter the file path to encrypt: " file_path

encrypt_file "$file_path" "$password"
echo "File encrypted successfully."

read -p "Enter the encrypted file path to decrypt: " enc_file_path

decrypt_file "$enc_file_path" "$password"
echo "File decrypted successfully."
