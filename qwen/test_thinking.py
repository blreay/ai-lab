import json, time, urllib.request

#URL = "http://121.40.190.90:8000/v1/chat/completions"
URL = "http://127.0.0.1:8000/v1/chat/completions"
PROMPT = "一支铅笔和一个笔记本一共25元，笔记本比铅笔贵20元，铅笔多少钱？请简要说明。"

def call(label, kwargs=None, max_tokens=1200):
    body = {"model":"qwen-local","messages":[{"role":"user","content":PROMPT}],
            "max_tokens":max_tokens,"temperature":0.7,"seed":42}
    if kwargs: body["chat_template_kwargs"] = kwargs
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type":"application/json"})
    t0=time.time()
    try:
        with urllib.request.urlopen(req, timeout=300) as r: d=json.load(r)
    except Exception as e:
        print(f"{label:42s} ERROR {e}"); return
    dt=time.time()-t0
    m=d["choices"][0]["message"]
    rsn = m.get("reasoning") or m.get("reasoning_content") or ""
    ct  = m.get("content") or ""
    u=d.get("usage",{})
    ctd=u.get("completion_tokens_details")
    fin=d["choices"][0].get("finish_reason")
    print(f"{label:42s} {dt:6.1f}s comp_tok={u.get('completion_tokens'):5} "
          f"details={ctd} reasoning_chars={len(rsn):6} content_chars={len(ct):4} fin={fin}")
    if rsn: print(f"    think头: {rsn[:100]!r}")
    else:   print(f"    content头: {ct[:80]!r}")

call("① default(无kwargs)")
call("② enable_thinking=true",  {"enable_thinking":True})
call("③ enable_thinking=false", {"enable_thinking":False})
call("④ thinking_budget=128",   {"thinking_budget":128})
call("⑤ thinking_budget=4096",  {"thinking_budget":4096})
call("⑥ think_level=low",       {"think_level":"low"})
call("⑦ think_level=high",      {"think_level":"high"})
call("⑧ thinking_level=low",    {"thinking_level":"low"})
call("⑨ thinking_level=high",   {"thinking_level":"high"})
call("⑩ reasoning_effort=low",  {"reasoning_effort":"low"})
call("⑪ reasoning_effort=high", {"reasoning_effort":"high"})
call("⑫ enable_thinking+budget128", {"enable_thinking":True,"thinking_budget":128})

