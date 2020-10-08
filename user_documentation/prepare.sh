#!/bin/bash

# To compile the documentation, one needs the packages to be installed.
# To prepare compilation do the following:

set -ex

PDIR=env/doc

rm -rf "$PDIR"

# Create a virtual environment:
virtualenv "$PDIR"

# Activate it (this step is ALWAYS required before compiling)
source "$PDIR"/bin/activate

pip install --upgrade pip

# Install the locally checked out packages:
pip install -r requirements.txt

set +ex

echo "Virtualenv created. To activate, use this command:"
echo "source '$PDIR/bin/activate'"
