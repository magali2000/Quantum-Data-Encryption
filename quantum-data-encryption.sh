#!/bin/bash

# Function to check if public key exists
check_public_key_exists() {
  if [ ! -f "$1" ]; then
    echo "Public key $1 does not exist."
    exit 1
  fi
}

# Function to check if private key exists
check_private_key_exists() {
  if [ ! -f "$1" ]; then
    echo "Private key $1 does not exist."
    exit 1
  fi
}

# User input for logging choice
echo "Do you want to log the operations? (y/n): "
read log_choice

# Function to log operations
log_operation() {
  if [[ "$log_choice" == "y" || "$log_choice" == "Y" ]]; then
    echo "$(date): $1" >> log.txt
  fi
}

# Function to encrypt file using asymmetric encryption
encrypt_file_asymmetric() {
  check_file_exists "$1"
  check_file_encrypted "$1"
  check_public_key_exists "$2"
  openssl rsautl -encrypt -inkey "$2" -pubin -in "$1" -out "$1.enc"
  check_command_status "File encryption"
  log_operation "Encrypted file $1."
  read -p "Do you want to delete the original file? (y/n): " del
  if [[ "$del" == "y" || "$del" == "Y" ]]; then
    rm "$1"
    log_operation "Deleted original file $1."
  fi
}

# Function to decrypt file using asymmetric encryption
decrypt_file_asymmetric() {
  check_file_exists "$1"
  check_file_decrypted "$1"
  check_private_key_exists "$2"
  openssl rsautl -decrypt -inkey "$2" -in "$1" -out "${1%.enc}"
  check_command_status "File decryption"
  echo "$(date): Decrypted file $1." >> log.txt
  read -p "Do you want to delete the encrypted file? (y/n): " del
  if [[ "$del" == "y" || "$del" == "Y" ]]; then
    rm "$1"
    echo "$(date): Deleted encrypted file $1." >> log.txt
  fi
}

# User input for encryption method choice
echo "What encryption method would you like to use? (symmetric/asymmetric): "
read method

case $method in
  "symmetric")
    # Existing code for symmetric encryption
    ;;
  "asymmetric")
    echo "Enter the operation (encrypt/decrypt): "
    read operation
    case $operation in
      "encrypt")
        echo "Enter the public key path: "
        read public_key_path
        check_public_key_exists "$public_key_path"
        for file_path in "${file_paths[@]}"
        do
          encrypt_file_asymmetric "$file_path" "$public_key_path"
          echo "File $file_path encrypted successfully."
        done
        ;;
      "decrypt")
        echo "Enter the private key path: "
        read private_key_path
        check_private_key_exists "$private_key_path"
        for enc_file_path in "${enc_file_paths[@]}"
        do
          decrypt_file_asymmetric "$enc_file_path" "$private_key_path"
          echo "File $enc_file_path decrypted successfully."
        done
        ;;
      *)
        echo "Invalid operation. Please enter either 'encrypt' or 'decrypt'."
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Invalid method. Please enter either 'symmetric' or 'asymmetric'."
    exit 1
    ;;
esac

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
# Function to compress file
compress_file() {
  check_file_exists "$1"
  gzip "$1"
  check_command_status "File compression"
  log_operation "Compressed file $1."
}

# Function to decompress file
decompress_file() {
  check_file_exists "$1"
  if [[ $1 != *.gz ]]; then
    echo "File $1 is not compressed."
    return 1
  fi
  gunzip "$1"
  check_command_status "File decompression"
  log_operation "Decompressed file $1."
}

# Modify the encrypt_file function
encrypt_file() {
  check_file_exists "$1"
  check_file_encrypted "$1"
  compress_file "$1"
  openssl aes-256-cbc -a -salt -in "$1.gz" -out "$1.enc" -pass pass:"$2" 2>/dev/null
  check_command_status "File encryption"
  log_operation "Encrypted file $1."
  read -p "Do you want to delete the original compressed file? (y/n): " del
  if [[ "$del" == "y" || "$del" == "Y" ]]; then
    rm "$1.gz"
    log_operation "Deleted original compressed file $1.gz."
  fi
}

# Modify the decrypt_file function
decrypt_file() {
  check_file_exists "$1"
  check_file_decrypted "$1"
  openssl aes-256-cbc -d -a -in "$1" -out "${1%.enc}.gz" -pass pass:"$2" 2>error.log
  if [ $? -eq 0 ]; then
    decompress_file "${1%.enc}.gz"
    log_operation "Decrypted file $1."
    read -p "Do you want to delete the encrypted file? (y/n): " del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
      rm "$1"
      log_operation "Deleted encrypted file $1."
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
}

# Check if openssl is installed
check_openssl_installed

# Function to get password or key file
get_password_or_keyfile() {
  echo "Do you want to use a password or a key file? (password/keyfile): "
  read method
  case $method in
    "password")
      get_password
      ;;
    "keyfile")
      echo "Enter the path to the key file: "
      read keyfile
      check_file_exists "$keyfile"
      password=$(cat "$keyfile")
      ;;
    *)
      echo "Invalid method. Please enter either 'password' or 'keyfile'."
      exit 1
      ;;
  esac
}

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
      get_password_or_keyfile
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
      get_password_or_keyfile
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
