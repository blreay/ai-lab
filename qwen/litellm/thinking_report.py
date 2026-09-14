#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
thinking_report.py — 思考电表报表
用法:
  python3 thinking_report.py            # 按 天×来源×IP 汇总
  python3 thinking_report.py --level    # 档位分布
  python3 thinking_report.py --slow 20  # 列出超过20秒的慢请求
"""
import json
import sys
import collections

PATH = "/data/ai/litellm/thinking_usage.jsonl"

recs = []
for line in open(PATH, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        recs.append(json.loads(line))
    except Exception:
        pass

if not recs:
    print("暂无数据")
    sys.exit(0)

mode = sys.argv[1] if len(sys.argv) > 1 else ""

if mode == "--level":
    agg = collections.Counter((r["ts"][:10], r.get("level", "?")) for r in recs)
    print(f"{'日期':12s} {'档位':10s} 次数")
    for (d, lv), n in sorted(agg.items()):
        print(f"{d:12s} {lv:10s} {n}")

elif mode == "--slow":
    thr = float(sys.argv[2]) if len(sys.argv) > 2 else 20.0
    slow = [r for r in recs if r.get("latency_ms", 0) > thr * 1000]
    slow.sort(key=lambda r: -r["latency_ms"])
    for r in slow[:40]:
        print(f"{r['ts']} {r['src']:12s} {r.get('ip',''):15s} "
              f"{r['latency_ms']/1000:7.1f}s in={r['prompt_tokens']:7d} "
              f"out={r['completion_tokens']:6d} think≈{r['reasoning_tokens_est']:6d} "
              f"lvl={r['level']} {r.get('error','')[:80]}")
    print(f"-- 共 {len(slow)} 条 > {thr}s --")

else:
    agg = collections.defaultdict(lambda: {"n": 0, "err": 0, "in": 0, "out": 0,
                                           "think": 0, "cache": 0, "lat": 0})
    for r in recs:
        key = (r["ts"][:10], r["src"], r.get("ip", ""))
        a = agg[key]
        a["n"] += 1
        if r["kind"] != "ok":
            a["err"] += 1
        a["in"] += r.get("prompt_tokens") or 0
        a["out"] += r.get("completion_tokens") or 0
        a["think"] += r.get("reasoning_tokens_est") or 0
        a["cache"] += r.get("cached_tokens") or 0
        a["lat"] += r.get("latency_ms") or 0
    print(f"{'日期':10s} {'来源':12s} {'IP':15s} {'请求':>4s} {'错误':>3s} "
          f"{'输入tok':>10s} {'缓存tok':>10s} {'输出tok':>8s} {'思考≈tok':>8s} "
          f"{'思考占输出':>6s} {'平均时延':>6s}")
    for k in sorted(agg):
        a = agg[k]
        pct = f"{a['think']*100//max(a['out'],1)}%"
        avg = f"{a['lat']/max(a['n'],1)/1000:.1f}s"
        print(f"{k[0]:10s} {k[1]:12s} {k[2]:15s} {a['n']:4d} {a['err']:3d} "
              f"{a['in']:10,d} {a['cache']:10,d} {a['out']:8,d} {a['think']:8,d} "
              f"{pct:>6s} {avg:>6s}")
