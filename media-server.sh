#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-media-server}"

usage() {
	cat <<'EOF'
Usage:
	media-server.sh <command> [args...]
	<command> [args...] | media-server.sh

Examples:
	media-server.sh mediamtx /etc/mediamtx.yml
	docker logs -f mediamtx | media-server.sh

Environment variables:
	APP_NAME   Service name shown in output (default: media-server)
EOF
}

format_logs() {
	APP_NAME="$APP_NAME" perl -ne '
		use strict;
		use warnings;
		use POSIX qw(strftime);

		sub normalize_level {
			my ($level) = @_;
			my $l = lc($level // "info");
			return "info"  if $l eq "inf";
			return "warn"  if $l eq "wrn";
			return "error" if $l eq "err";
			return "debug" if $l eq "dbg" || $l eq "deb";
			return "fatal" if $l eq "fat";
			return $l;
		}

		sub normalize_ms {
			my ($ms) = @_;
			$ms = "" unless defined $ms;
			return "000" if $ms eq "";
			return $ms . "00" if length($ms) == 1;
			return $ms . "0" if length($ms) == 2;
			return substr($ms, 0, 3);
		}

		chomp;
		my $app = $ENV{APP_NAME} // "media-server";

		if (/^(\d{4})\/(\d{2})\/(\d{2}) (\d{2}:\d{2}:\d{2})(?:\.(\d{1,3}))? ([A-Z]{3,5}) (.*)$/) {
			my ($y, $mon, $d, $time, $ms, $level, $msg) = ($1, $2, $3, $4, $5, $6, $7);
			my $ts = sprintf("%s-%s-%s %s.%s", $y, $mon, $d, $time, normalize_ms($ms));
			printf("[%s] [%s] [%s] %s\n", $ts, $app, normalize_level($level), $msg);
			next;
		}

		if (/^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})(?:\.(\d{1,3}))? ([A-Z]{3,5}) (.*)$/) {
			my ($date, $time, $ms, $level, $msg) = ($1, $2, $3, $4, $5);
			my $ts = sprintf("%s %s.%s", $date, $time, normalize_ms($ms));
			printf("[%s] [%s] [%s] %s\n", $ts, $app, normalize_level($level), $msg);
			next;
		}

		# Fallback for lines that do not match known MediaMTX timestamp patterns.
		my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
		printf("[%s.000] [%s] [info] %s\n", $now, $app, $_);
	'
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

if [[ -t 0 ]]; then
	if [[ $# -eq 0 ]]; then
		usage >&2
		exit 1
	fi

	"$@" 2>&1 | format_logs
else
	format_logs
fi
