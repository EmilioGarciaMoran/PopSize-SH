#!/bin/bash
set -e
apt-get install -y awscli 2>/dev/null || true
aws s3 cp s3://sima-egarmo-2026/eastwest/scripts/run_act2_v2.sh \
    /tmp/run_act2_v2.sh --region eu-west-1
chmod +x /tmp/run_act2_v2.sh
bash /tmp/run_act2_v2.sh
