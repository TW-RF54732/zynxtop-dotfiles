#!/usr/bin/env python3
import json
import os
import sys
import tempfile


def main():
    try:
        payload = json.loads(sys.stdin.readline())
        config = payload.get("config", "")
        if not isinstance(config, str) or not config.strip():
            raise ValueError("empty configuration")

        descriptor, path = tempfile.mkstemp(
            prefix="quickshell-wireguard-", suffix=".conf", dir="/tmp", text=True
        )
        try:
            os.fchmod(descriptor, 0o600)
            stream = os.fdopen(descriptor, "w", encoding="utf-8")
            descriptor = -1
            with stream:
                stream.write(config)
        except Exception:
            if descriptor >= 0:
                os.close(descriptor)
            os.unlink(path)
            raise

        print(path, flush=True)
        return 0
    except Exception as error:
        print(f"Unable to prepare configuration: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
