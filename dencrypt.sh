#!/bin/bash
# (C) 2025 Benjamin Steenkamer
# If input file is encrypted with GPG, attempt to decrypt it
#   Asks for password to decrypt with; does not cache the password
#   Outputs decrypted file to "*.out"
# Otherwise, encrypt input file with AES256
#   Asks for password; will not cache it
#   Outputs encrypted file to "*.gpg"

if file "$1" | grep -q "encrypted data"; then
    echo "Decrypting"
    gpg --no-symkey-cache --output "${1}.out" --decrypt "$1"
else
    echo "Encrypting"
    gpg --no-symkey-cache --symmetric --cipher-algo AES256 "$1"
fi
