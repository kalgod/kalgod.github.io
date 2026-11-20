#!/bin/bash
# 抓取 Google Scholar 引用数并推送到 google-scholar-stats 分支。
# GitHub Actions 的 IP 被 Google 封了，所以改在自己服务器上用 cron 跑。
# 用法: bash update.sh          (crontab: 0 8 * * * bash /home/cjh/work/kalgod.github.io/google_scholar_crawler/update.sh >> /home/cjh/work/scholar_update.log 2>&1)
set -e
export GOOGLE_SCHOLAR_ID="B6V-OUQAAAAJ"
REPO="https://github.com/kalgod/kalgod.github.io.git"
BRANCH="google-scholar-stats"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK=$(mktemp -d /tmp/scholar.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

source /home/cjh/anaconda3/etc/profile.d/conda.sh
conda activate video

echo "[$(date '+%F %T')] start"
cd "$WORK"
python "$SRC_DIR/main.py" > /dev/null

new=$(python -c "import json;print(json.load(open('results/gs_data_shieldsio.json'))['message'])")
old=$(curl -sf "https://raw.githubusercontent.com/kalgod/kalgod.github.io/$BRANCH/gs_data_shieldsio.json" | python -c "import sys,json;print(json.load(sys.stdin)['message'])" 2>/dev/null || echo "none")
echo "citations: github=$old scholar=$new"

if [ "$new" = "$old" ]; then
  echo "unchanged, skip push"
  exit 0
fi

cd results
git init -q
git checkout -q -b "$BRANCH"
git add gs_data.json gs_data_shieldsio.json
git -c user.name=kalgod -c user.email=2396980409@qq.com commit -q -m "Updated Citation Data $(date +%F)"
git push -q --force "$REPO" "$BRANCH"
echo "pushed $new"
