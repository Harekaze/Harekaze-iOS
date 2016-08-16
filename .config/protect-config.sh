#!/bin/sh
SRCROOT="$(pwd)/$(dirname $0)/"
git update-index --skip-worktree "${SRCROOT}"/.config/*
