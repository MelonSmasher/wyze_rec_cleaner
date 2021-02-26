# Wyze Recording Cleaner

Simple script to clean Wyze camera recordings on NFS shares. This script can run from a machine that has the same NFS mount as your Wyze cameras and will clean old recordings and prune empty directories.

## Setup

Grab the files:

```bash
git clone https://github.com/MelonSmasher/wyze_rec_cleaner.git
cd wyze_rec_cleaner
cp .env.example .env
```

After grabbing the files edit `.env` with values that make sense.

## Usage

```bash
cd wyze_rec_cleaner
./wyze_rec_cleaner.sh
```
