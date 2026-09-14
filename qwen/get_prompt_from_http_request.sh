#!bin/bash
#

funtion main_jq {
jq -r '
    [ .messages[]
      | select(.role=="user")
      | ( if (.content|type)=="string" then .content
          else (.content|map(select(.type=="text")|.text)|join("\n"))
          end )
      | select(. != "")
      | select(test("^<system-reminder>|^<command-message>|^Base directory for this skill:|The user stepped away and is coming back|^The user sent a new message while you
      were working")|not)
    ] | last // empty
  ' 1
}

function main_python {
python3 -c "
import json,sys,re
d=json.load(open(sys.argv[1],encoding='utf-8'))
def texts(m):
    c=m.get('content')
    if isinstance(c,str): return [c]
    if isinstance(c,list): return [b.get('text','') for b in c if isinstance(b,dict) and b.get('type')=='text']
    return []
synth=re.compile(r'^<system-reminder>|^<command-message>|^Base directory for this skill:|The user stepped away and is coming back|^The user sent a new message while you were working')
users=[t for m in d['messages'] if m.get('role')=='user' for t in texts(m) if t.strip() and not synth.search(t)]
print(users[-1] if users else '')
" 1 > last_user_input.txt && cat last_user_input.txt
}
