#!/bin/bash

# Function to encrypt data
encrypt_data() {
  echo -n "$1" | openssl aes-256-cbc -a -salt -pass pass:"$2"
}

# Function to decrypt data
decrypt_data() {
  echo -n "$1" | openssl aes-256-cbc -d -a -pass pass:"$2"
}

# Test the functions
password="my_password"
original_data="Sensitive data"

encrypted_data=$(encrypt_data "$original_data" "$password")
echo "Encrypted data: $encrypted_data"

decrypted_data=$(decrypt_data "$encrypted_data" "$password")
echo "Decrypted data: $decrypted_data"
