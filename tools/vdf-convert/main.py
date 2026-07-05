#!/usr/bin/env python3
import sys
import argparse

import json
import steam.vdf as vdf

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest="command", required=True)
subparsers.add_parser("to-json")
subparsers.add_parser("from-json")

if __name__ == "__main__":
    args = parser.parse_args()

    if args.command == "to-json":
        data = vdf.load(sys.stdin)
        sys.stdout.write(json.dumps(data))

    elif args.command == "from-json":
        data = json.load(sys.stdin)
        sys.stdout.write(vdf.dumps(data).decode("utf-16"))
