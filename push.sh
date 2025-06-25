#!/bin/sh
set -eu
export LC_ALL='C'

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${0:?}")" && pwd -P)"

main() {
	updatedSources="$(git status --porcelain=v1 -- "${SCRIPT_DIR:?}/data/" | awk -F'/' '{printf("* %s\n",$2)}' | sort | uniq)"
	updatedReleased="$(git status --porcelain=v1 -- "${SCRIPT_DIR:?}/released/" | awk -F'/' '{printf("* %s\n",$2)}' | sort | uniq)"
	commitMsg=""
	if [ -n "${updatedSources}" ]; then
		commitMsg="$(printf '%s\n%s' 'Updated sources:' "${updatedSources}")"
		git add -- "${SCRIPT_DIR:?}/data/"
	fi
	if [ -n "${updatedReleased}" ]; then
		commitMsg="$commitMsg\n$(printf '%s\n%s' 'Updated released:' "${updatedReleased}")"
		git add -- "${SCRIPT_DIR:?}/released/"
	fi
	if [ -n "$commitMsg" ]; then
		git commit -m "$commitMsg"
		git push origin HEAD
	fi
}

main "${@-}"
