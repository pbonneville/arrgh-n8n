#!/bin/bash

# Script to add n8n.paulbonneville.test to /etc/hosts

echo "Adding n8n.paulbonneville.test to /etc/hosts..."

# Check if the entry already exists
if grep -q "n8n.paulbonneville.test" /etc/hosts; then
    echo "Entry already exists in /etc/hosts"
else
    echo "127.0.0.1    n8n.paulbonneville.test" | sudo tee -a /etc/hosts
    echo "Successfully added n8n.paulbonneville.test to /etc/hosts"
fi

# Test the entry
echo ""
echo "Testing the new host entry:"
ping -c 1 n8n.paulbonneville.test

echo ""
echo "You can now access n8n locally at: http://n8n.paulbonneville.test:5678"