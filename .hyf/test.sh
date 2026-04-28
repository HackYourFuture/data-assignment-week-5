#!/usr/bin/env bash
set -euo pipefail

# Run your test scripts here.
# Auto grade tool will execute this file within the .hyf working directory.
# The result should be stored in score.json file with the format shown below.
cat << EOF > score.json
{
  "score": 0,
  "pass": true,
  "passingScore": 0
}
EOF
