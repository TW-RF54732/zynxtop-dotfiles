"""Read the current account without depending on a desktop account service."""
import json
import os
from pathlib import Path
import pwd

account = pwd.getpwuid(os.getuid())
home = Path(account.pw_dir)
avatar = next((p.as_uri() for p in (home / ".face.icon", home / ".face")
               if p.is_file() and os.access(p, os.R_OK)), "")
print(json.dumps({"displayName": account.pw_gecos.split(",")[0] or account.pw_name,
                  "avatar": avatar}))
