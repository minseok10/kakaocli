# AGENTS.md — KakaoCLI for AI Agents

Instructions for AI agents that read and send KakaoTalk messages with `kakaocli`.

Reading comes from KakaoTalk's local database: it is fast, needs no UI, and covers every message stored on this Mac. Sending drives the KakaoTalk app through macOS Accessibility and is deliberately strict — it refuses rather than guesses.

## Prerequisites

- macOS 14+ with the KakaoTalk desktop app installed and logged in
- `kakaocli` built and in PATH (or `swift run kakaocli`)
- System Settings > Privacy & Security, granted to the app that runs kakaocli (your terminal, editor or agent host):
  - **Full Disk Access** — every read command, and `send` (it confirms delivery in the DB)
  - **Accessibility** — `send`, `harvest`, `inspect`

Check with:

```bash
kakaocli status   # install, permissions, userId, database name
kakaocli auth     # database decryption works
```

The first run may take a few seconds to recover your KakaoTalk userId; it is then cached in `~/.kakaocli/userid` and later commands start in well under a second.

## Which Command to Use

| You want to… | Command |
|--------------|---------|
| List chats and their IDs | `kakaocli chats --json --limit 999999` |
| Latest messages in a chat, or across all chats | `kakaocli messages --chat-id ID --since 1h --json` |
| Read a whole chat, page by page | `kakaocli history --chat-id ID --limit 100` |
| Find messages by text | `kakaocli history --contains "word" --limit 50` (or `kakaocli search "word" --json`) |
| Anything else in the DB | `kakaocli query "SELECT …"` |
| React to new messages as they arrive | `kakaocli sync --follow` |
| Send a message | `kakaocli send "Exact Chat Name" "text"` |

Prefer `--chat-id` over `--chat "Name"` once you know the ID: `messages --chat` is a substring match and takes the first chat that contains the text.

## Reading

### Chats

```bash
kakaocli chats --json --limit 999999
```

```json
[{"id": 142943519989217, "display_name": "지수", "type": "direct", "member_count": 2, "unread_count": 0, "last_message_at": "2026-10-27T03:14:58Z"}]
```

`--limit` defaults to 50; pass a large value to get every chat.

| `type` | `type_code` | Chat |
|--------|-------------|------|
| `direct` | 0 | 1:1 with a person |
| `group` | 1 | Group chat |
| `channel` | 2 | KakaoTalk Channel (businesses and services, mostly AlimTalk notifications) |
| `open` | 4 | Open chat |
| `self` | 5 | Self-chat (나와의 채팅) |
| `system` | 9999 | Internal placeholder; ignore |
| `unknown` | other | Unrecognized code; check `type_code` |

Skip `channel` chats when looking for messages from people.

### Latest messages

```bash
kakaocli messages --chat-id 12345 --limit 100 --json
kakaocli messages --since 24h --json          # all chats; --since takes 30m, 1h, 7d …
```

```json
[{"id": 3960544519672051713, "chat_id": 12345, "sender_id": 789, "sender": "김지수", "text": "안녕!", "type": "text", "type_code": 1, "timestamp": "2026-10-27T03:14:58Z", "is_from_me": false}]
```

Results are newest first. `deleted: true` appears on messages deleted for everyone.

### Whole chat history (paginated)

`messages` stops at `--limit`. `history` pages through everything stored locally using a cursor and always prints JSON.

```bash
kakaocli history --chat-id 12345 --limit 100                       # newest page
kakaocli history --chat-id 12345 --limit 100 --before "<cursor>"   # next older page
kakaocli history --chat-id 12345 --after 0.0 --limit 500           # oldest first, from the start
```

Each row has `cursor` (`<sentAt>.<logId>`). Pass the **last** row's cursor to `--before` (or `--after` when walking forward) and stop when the result is `[]`.

```python
import json, subprocess

def read_chat(chat_id):
    cursor = None
    while True:
        args = ["kakaocli", "history", "--chat-id", str(chat_id), "--limit", "500"]
        if cursor:
            args += ["--before", cursor]
        page = json.loads(subprocess.run(args, capture_output=True, text=True, check=True).stdout)
        if not page:
            return
        yield from page
        cursor = page[-1]["cursor"]
```

Other filters: `--contains TEXT`, `--since`/`--until` (Unix seconds), `--exclude-chat-id ID` (repeatable), `--log-id ID`. `--limit` is 1–5000.

Extra fields per row: `type`, `type_code`, `sent_at` (Unix seconds), `attachment` (KakaoTalk's attachment data as a JSON object — photos, files, emoticons, reply targets; omitted for plain text), `local_file_path` (only if the file was downloaded on this Mac), `deleted`.

### Message types

`type` is one of: `text`, `photo`, `multi_photo`, `video`, `audio`, `file`, `emoticon`, `reply`, `location`, `vote`, `post` (notices), `schedule`, `call`, `system` (join/leave events), `custom` (rich cards), `notification` (AlimTalk), `contact`, `gift`, `kakaolink`, `avatar`, `lottery`, `profile`, `nudge`, `search`, `plus_friend`, `unknown`. `type_code` is the raw KakaoTalk code; use it when `type` is `unknown`.

### Raw SQL

```bash
kakaocli query "SELECT chatId, COUNT(*) FROM NTChatMessage GROUP BY chatId ORDER BY 2 DESC LIMIT 10"
kakaocli schema
```

Returns a JSON array of rows (arrays). SQL `NULL` is `null`; BLOB columns are base64 strings. Read-only.

### Coverage

The local DB holds what KakaoTalk on this Mac has synced — chats opened on this Mac, often going back years. Messages never loaded on this Mac are not there; `kakaocli harvest --scroll` can load older history through the UI.

## Watching for New Messages

```bash
kakaocli sync --follow                                          # NDJSON on stdout
kakaocli sync --follow --webhook http://localhost:8080/kakao   # POST batches as JSON arrays
kakaocli sync                                                   # one-shot: {"status":"ready","max_log_id":…}
```

One line per new message:

```json
{"type":"message","log_id":123,"chat_id":456,"chat_name":"Mom","sender_id":789,"sender":"Mom","text":"Are you coming?","message_type":1,"message_type_name":"text","deleted":false,"timestamp":"2026-02-20T10:30:00Z","is_from_me":false}
```

Options: `--interval <seconds>` (default 2), `--since-log-id <id>` to resume from a saved point. Save the last `log_id` you processed and pass it back after a restart so nothing is missed.

`sync` sees every chat, including muted ones and your own messages (filter with `is_from_me`). Messages you send appear once KakaoTalk receives the server ack.

## Sending

```bash
kakaocli send "Exact Chat Name" "Message text"
kakaocli send --me _ "Self-chat message"      # self-chat (나와의 채팅); the name argument is ignored
kakaocli send --dry-run "Name" "text"         # preview only
```

How the chat is chosen:

1. A chat whose name equals the argument exactly wins.
2. Otherwise a substring is accepted only if it matches exactly one chat. Several matches → error listing the candidates; retry with one of those exact names.
3. The opened window's title must equal that chat's name, or nothing is sent.

Before pressing Return, `send` also refuses if the chat's input box already has a draft, and checks that the box holds exactly your text. Key events go only to the KakaoTalk process.

After Return, `send` waits for the message in the database (`--confirm-timeout`, default 10s).

| Exit status | Meaning | What to do |
|-------------|---------|------------|
| `0` | Confirmed in the database | Done |
| `2` | Return was pressed, but the message was not seen in time | **Do not retry automatically.** Check the chat (e.g. `kakaocli messages --chat-id ID --limit 5 --json`) before sending again, or it may be sent twice |
| other non-zero | Failed before Return | Nothing was sent; fix the cause in the error and retry |

Other constraints:

- KakaoTalk is launched and logged in automatically if needed (see Lifecycle).
- The chat window is opened, used and closed; any other open chat windows are closed first.
- Leave at least 2 seconds between sends.

`send` takes a chat **name**, not an ID. To reply to a message you read by `chat_id`, look the name up with `kakaocli chats --json` first.

## Agent Integration Pattern

```python
import json, subprocess

def run_json(*args):
    return json.loads(subprocess.run(["kakaocli", *args], capture_output=True, text=True, check=True).stdout)

names = {c["id"]: c["display_name"] for c in run_json("chats", "--json", "--limit", "999999")}

for msg in run_json("messages", "--since", "5m", "--json"):
    if msg["is_from_me"] or not needs_response(msg):
        continue
    reply = draft_reply(msg)
    if not user_approves(names[msg["chat_id"]], reply):    # always confirm sends to other people
        continue
    result = subprocess.run(["kakaocli", "send", names[msg["chat_id"]], reply])
    if result.returncode == 2:
        report("Sent but unconfirmed — check KakaoTalk before retrying")
```

For real-time handling, read `kakaocli sync --follow` line by line instead of polling `messages`:

```bash
kakaocli sync --follow | while read -r line; do
  echo "$line" | jq -r 'select(.is_from_me | not) | .text' | process_message
done
```

## Lifecycle and Login

You do **not** need to launch or log into KakaoTalk yourself; `send` and `harvest` do it:

| Situation | What happens |
|-----------|-------------|
| App not running | Launches KakaoTalk |
| Login screen showing | Fills stored credentials and logs in |
| "Keep me logged in" | Checked automatically, so later launches skip login |
| Window hidden (menu bar only) | Detected via the status bar menu |
| Already logged in | Proceeds immediately |

Read commands never need the app running.

```bash
kakaocli login --status                                     # app state + whether credentials are stored
kakaocli login --email user@example.com --password '...'    # store credentials (non-interactive)
kakaocli login --clear                                      # remove them
```

Pass `--email` and `--password` in scripts: the interactive prompt needs a real terminal. Credentials are stored in the login Keychain (service `com.kakaocli.credentials`, accounts `kakaotalk-email` / `kakaotalk-password`) and are readable by any process of the current macOS user.

App states from `login --status`: `loggedIn` (ready), `loginScreen` (will auto-login), `notRunning` (will auto-launch), `launching`, `unknown` (transient).

## Harvest (Chat Names and Older History)

```bash
kakaocli harvest                          # capture chat display names from the UI
kakaocli harvest --scroll --top 20        # also load older messages for the 20 most recent chats
kakaocli harvest --dry-run
```

Options: `--top N`, `--scroll`, `--max-clicks N` ("View Previous Chats" clicks per chat, default 10), `--scroll-delay SECONDS` (default 1.5). Chats with unread messages are skipped so they are not marked as read. Names are saved to `~/.kakaocli/metadata.json`. The Talk Drive Plus paywall limits how far back history can be loaded.

Most names are already resolved from the database (direct chats, open chats, unnamed groups), so `harvest` is rarely needed just for names.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `couldn't be opened because you don't have permission` (read commands) | Grant Full Disk Access to the app running kakaocli, then restart that app |
| `send needs to read the KakaoTalk database` | Same — grant Full Disk Access to the app named in the error; nothing was sent |
| `Chat '…' not found` | Run `kakaocli chats --json` to see the names |
| `matches N chats` | Retry with one of the exact names listed |
| `Opened '…' instead of '…'` | A different chat opened; nothing was sent. Retry |
| `already has a draft` | Clear that chat's input box in KakaoTalk; nothing was sent |
| `Could not confirm the message text in the input box` | Nothing was sent; retry |
| `send` exits with status 2 | Sent but unconfirmed — check the chat before retrying |
| `Could not find the message input field` | Follow the `AXManualAccessibility` steps printed in the error |
| `Keychain error` | `kakaocli login --clear`, then store credentials again |
| `Login did not succeed` | Re-store credentials with `kakaocli login --email … --password …` |
| `No open windows` | Open KakaoTalk manually once |
| userId wrong after switching accounts | Usually self-heals; otherwise delete `~/.kakaocli/userid` |

Run `send` with `KAKAOCLI_DEBUG=1` for a step-by-step trace of the UI automation.

## Safety Rules

1. **Never send test messages to other people's chats.** Test with `--me` only.
2. **Confirm before sending** to anyone else — show the user the exact chat name and text first.
3. **Never auto-retry a send that exited with status 2.**
4. **Rate limit** — at least 2 seconds between sends.
5. **Respect hours** — avoid sending between 11 PM and 7 AM unless urgent.
6. **Don't run `harvest --scroll` casually** — it opens chats in the UI.
