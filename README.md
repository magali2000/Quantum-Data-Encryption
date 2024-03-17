# README

## Overview
This bash script provides a set of functions to check password strength, encrypt and decrypt data, and encrypt and decrypt files. It uses OpenSSL for encryption and decryption.

## Functions
1. `check_password_strength`: This function checks if the provided password is strong. A strong password is at least 8 characters long and includes uppercase, lowercase, numbers, and special characters.

2. `encrypt_data`: This function encrypts the provided data using the provided password.

3. `decrypt_data`: This function decrypts the provided encrypted data using the provided password.

4. `encrypt_file`: This function encrypts the provided file using the provided password. The encrypted file is saved with the extension `.enc`.

5. `decrypt_file`: This function decrypts the provided encrypted file using the provided password. The decrypted file is saved without the `.enc` extension.

## Usage
1. Run the script. It will prompt you to enter a password. The script will check if the password is strong. If it's not, the script will exit.

2. Next, it will prompt you to enter data. The script will encrypt this data using the provided password and then decrypt it.

3. The script will then prompt you to enter a file path. It will encrypt this file using the provided password.

4. Finally, the script will prompt you to enter an encrypted file path. It will decrypt this file using the provided password.

## Requirements
- OpenSSL must be installed on your system to use this script.
- The script must be run in a bash shell.

## Note
- The script does not handle errors beyond checking the success of the OpenSSL commands and the strength of the password. If an error occurs, the script will simply exit with a status of 1.
- The script does not check if the provided file paths exist or if they are readable/writable.
