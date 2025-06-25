# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Added plan to standardize all released blocklists to the following formats: hosts, adblock, unbound, and rpz.
- Identified that currently only "hosts" and "adblock" formats are present.
- Added initial unbound.conf and rpz.txt output for HaGeZi-Ultimate-Blocklist.
- Automated unbound.conf and rpz.txt output for all blocklists with hosts format in the release process (update.sh).
- All blocklist outputs are now named hosts.txt (list.txt removed/deprecated).
- adblock.txt is now generated for each blocklist from hosts.txt in the release process.
