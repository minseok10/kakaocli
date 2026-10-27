# kakaocli

**CLI tool for KakaoTalk on macOS — read chats, search messages, send texts, and integrate with AI agents.**

**macOS용 카카오톡 CLI 도구 — 채팅 읽기, 메시지 검색, 텍스트 전송, AI 에이전트 연동.**

<p align="center">
  <img src="assets/demo.svg" alt="kakaocli demo" width="820">
</p>

> [!NOTE]
> This tool reads KakaoTalk's local database and automates the UI via macOS Accessibility APIs. It does not reverse-engineer the KakaoTalk protocol or call any Kakao APIs. See [Disclaimer](#disclaimer) for details.

> [!IMPORTANT]
> **This is a maintained fork of [silver-flight-group/kakaocli](https://github.com/silver-flight-group/kakaocli).** Upstream has many open, unmerged PRs; this fork carries the fixes that matter for current KakaoTalk builds and agent use. See [Fork changes](#fork-changes--포크-변경-사항).
>
> **[silver-flight-group/kakaocli](https://github.com/silver-flight-group/kakaocli)의 포크입니다.** 원본 저장소에 머지되지 않은 PR이 많아, 최신 카카오톡과 에이전트 사용에 필요한 수정을 이 포크에 반영했습니다.

---

**[English](#overview)** | **[한국어](#개요)**

---

## Fork changes / 포크 변경 사항

| Area | Change | Upstream |
|------|--------|----------|
| `sync` | Skips KakaoTalk's pending `logId = Int64.max` rows, which used to freeze the sync cursor so no new messages were ever emitted again | [#17](https://github.com/silver-flight-group/kakaocli/pull/17) |
| `auth` / all commands | Caches the recovered userId in `~/.kakaocli/userid` (about 4s → 0.2s per command), revalidated against the active account | like [#6](https://github.com/silver-flight-group/kakaocli/pull/6)/[#20](https://github.com/silver-flight-group/kakaocli/pull/20) |
| `send` | Refuses ambiguous chat names and checks the opened window's title before typing | like [#25](https://github.com/silver-flight-group/kakaocli/pull/25)/[#31](https://github.com/silver-flight-group/kakaocli/pull/31) |
| `messages` / `search` / `sync` | Correct message type names (reply, file, emoticon, …) plus the raw `type_code`; deleted messages are flagged | — |
| `query` | NULL → `null`, BLOB → base64 (both used to be `""`) | like [#31](https://github.com/silver-flight-group/kakaocli/pull/31) |
| `history` | New: cursor-paginated message reads with attachments and filters | [#28](https://github.com/silver-flight-group/kakaocli/pull/28) |
| Chat names | Chat-list rows matched by name label; open/group/self-chat names resolved from the DB | [#11](https://github.com/silver-flight-group/kakaocli/pull/11), [#19](https://github.com/silver-flight-group/kakaocli/pull/19) |

| 영역 | 변경 |
|------|------|
| `sync` | 서버 응답 대기 중인 메시지(`logId = Int64.max`) 때문에 sync가 조용히 멈추던 문제 수정 |
| `auth` / 전체 | 찾아낸 userId를 `~/.kakaocli/userid`에 캐시 (명령당 약 4초 → 0.2초). 계정이 바뀌면 자동으로 다시 찾음 |
| `send` | 이름이 여러 채팅방에 걸리면 전송을 거부하고, 입력 전에 열린 창 제목이 맞는지 확인 |
| `messages` / `search` / `sync` | 메시지 종류(답장, 파일, 이모티콘 등)를 올바르게 표시하고 원래 코드(`type_code`)도 함께 출력. 삭제된 메시지 표시 |
| `query` | NULL은 `null`, BLOB은 base64로 출력 (이전에는 둘 다 `""`) |
| `history` | 새 명령: 커서 기반 페이지 넘기기, 첨부파일 정보, 검색·필터 |

## Overview

kakaocli lets AI agents (Claude Code, Cursor, custom bots) check and send your KakaoTalk messages — something Kakao's official APIs simply can't do.

- **AI Agent Integration** — JSON output for every command, MCP skill definition, webhook delivery, auto-login
- **Read** — list chats, view messages, full-text search, raw SQL queries
- **Send** — send messages to any chat via UI automation
- **Sync** — real-time NDJSON message stream with webhook support
- **Harvest** — bulk-capture chat names and load older message history

### Why?

Kakao's official APIs cannot read chat history, export conversations, or send free-form messages. If you want an AI agent to check your messages, summarize conversations, or reply on your behalf — there's no official way to do it. kakaocli fills that gap by reading the local database and automating the native macOS client.

## 개요

kakaocli는 AI 에이전트(Claude Code, Cursor, 커스텀 봇)가 카카오톡 메시지를 확인하고 보낼 수 있게 해줍니다 — 카카오 공식 API로는 불가능한 기능입니다.

- **AI 에이전트 연동** — 모든 명령의 JSON 출력, MCP 스킬 정의, 웹훅 전달, 자동 로그인
- **읽기** — 채팅 목록, 메시지 조회, 전체 텍스트 검색, SQL 쿼리
- **전송** — UI 자동화를 통한 메시지 전송
- **동기화** — 실시간 NDJSON 메시지 스트림 및 웹훅 지원
- **수집** — 채팅방 이름 일괄 수집 및 이전 메시지 로드

### 왜 필요한가요?

카카오 공식 API로는 채팅 기록을 읽거나, 대화를 내보내거나, 자유로운 메시지를 보낼 수 없습니다. AI 에이전트가 메시지를 확인하거나, 대화를 요약하거나, 대신 답장하게 하고 싶어도 공식적인 방법이 없습니다. kakaocli는 로컬 데이터베이스를 읽고 네이티브 macOS 클라이언트를 자동화하여 이 부분을 해결합니다.

## Getting Started / 시작하기

### 1. Install / 설치

**Build from source (this fork)**

```bash
brew install sqlcipher
git clone https://github.com/minseok10/kakaocli.git
cd kakaocli
swift build -c release
# Binary is at .build/release/kakaocli
# Either add to PATH or run directly:
.build/release/kakaocli status
# Or use swift run:
swift run kakaocli status
```

> [!NOTE]
> `brew install silver-flight-group/tap/kakaocli` installs the **upstream** version without this fork's fixes.

### 2. Grant permissions / 권한 부여

Your terminal app needs two permissions in **System Settings > Privacy & Security**:

터미널 앱에 다음 두 가지 권한이 필요합니다 (**시스템 설정 > 개인정보 보호 및 보안**):

- **Full Disk Access** (전체 디스크 접근) — to read KakaoTalk's encrypted database
- **Accessibility** (접근성) — for UI automation (sending messages, harvest)

> [!NOTE]
> Full Disk Access is required for all commands. Accessibility is only needed for `send`, `harvest`, and `inspect`.

### 3. Verify it works / 동작 확인

```bash
# Check KakaoTalk installation and permissions
kakaocli status

# Verify database decryption
kakaocli auth

# List your most recent chats
kakaocli chats --limit 10
```

If `auth` succeeds, you're all set. All read commands work immediately — no KakaoTalk login or window required.

`auth`가 성공하면 준비 완료입니다. 모든 읽기 명령은 카카오톡 창 없이도 바로 작동합니다.

### 4. Try it out / 사용해보기

```bash
# Search across all your messages
kakaocli search "점심"

# Read recent messages from a chat (substring match on name)
kakaocli messages --chat "지수" --since 7d

# Page through a whole chat, 100 messages at a time
kakaocli history --chat-id 123456 --limit 100

# Send a message (opens KakaoTalk UI automatically)
kakaocli send "지수" "안녕!"

# Send to self-chat (나와의 채팅) — safe for testing
kakaocli send --me _ "test message"

# Stream new messages as JSON
kakaocli sync --follow

# Run a custom SQL query against the database
kakaocli query "SELECT COUNT(*) FROM NTChatMessage"
```

> [!TIP]
> Use `--me` to send to your self-chat (나와의 채팅) when testing. This is the safest way to verify send functionality.

## Commands

### Read / 읽기

| Command | Description |
|---------|-------------|
| `kakaocli status` | Check KakaoTalk installation and permissions |
| `kakaocli auth` | Verify database decryption |
| `kakaocli chats` | List chats sorted by last activity |
| `kakaocli messages --chat "name"` | Show the latest messages from a chat (substring match) |
| `kakaocli history --chat-id ID` | Page through a chat's full local history (JSON, with attachments) |
| `kakaocli search "keyword"` | Full-text search across all messages |
| `kakaocli schema` | Dump raw database schema |
| `kakaocli query "SQL"` | Run read-only SQL against the decrypted database |

All read commands support `--json` for structured output.

모든 읽기 명령은 `--json` 옵션으로 구조화된 출력을 지원합니다.

`query` returns a JSON array of rows. SQL `NULL` is `null` and BLOB columns are base64 strings.

### History / 기록 조회

`messages` only returns the newest `--limit` messages. `history` pages through everything stored locally, using a cursor, and always prints JSON.

`messages`는 최신 메시지 N개만 보여줍니다. `history`는 커서로 페이지를 넘기며 로컬에 저장된 메시지를 끝까지 읽을 수 있습니다.

```bash
kakaocli history --chat-id 123 --limit 100                  # newest 100, newest first
kakaocli history --chat-id 123 --before 1790400000.4567     # the 100 before that cursor
kakaocli history --chat-id 123 --after 0.0                  # from the very first message, oldest first
kakaocli history --contains 점심 --exclude-chat-id 999       # search, skipping a chat
kakaocli history --chat-id 123 --since 1790000000 --until 1790400000   # Unix seconds
```

Every row has a `cursor` (`<sentAt>.<logId>`). Pass the last row's cursor to `--before` (older page) or `--after` (newer page) until an empty array comes back. `--limit` is 1–5000 (default 100). Use `kakaocli chats --json` to find chat IDs.

각 메시지에 `cursor` 값이 있습니다. 마지막 메시지의 cursor를 `--before`(이전 페이지)나 `--after`(다음 페이지)에 넘기고, 빈 배열이 나올 때까지 반복하면 됩니다.

```json
{
  "log_id": 3875347049196724225,
  "chat_id": 123,
  "sender_id": 789,
  "sender": "김지수",
  "text": "사진 보냄",
  "type": "photo",
  "type_code": 2,
  "sent_at": 1790400000,
  "cursor": "1790400000.3875347049196724225",
  "is_from_me": false,
  "attachment": {"k": "...", "s": 482113, "w": 1280, "h": 960},
  "local_file_path": "/Users/.../photo.jpg"
}
```

- `attachment` — KakaoTalk's attachment data as a JSON object (photos, files, emoticons, reply targets, …). Omitted for plain text.
- `local_file_path` — present only when the file was downloaded on this Mac.
- `deleted` — `true` when the message was deleted for everyone (its original content usually stays in the local DB).

### Message types / 메시지 종류

`messages`, `search` and `history` output a `type` name plus the raw `type_code`; `sync` outputs `message_type` (code) and `message_type_name`.

| `type` | Codes | | `type` | Codes |
|--------|-------|-|--------|-------|
| `text` | 1 | | `reply` | 26 |
| `photo` | 2 | | `multi_photo` | 27 |
| `video` | 3 | | `file` | 18 |
| `audio` | 5 | | `location` | 16 |
| `emoticon` | 6, 8, 12, 20, 22, 25 | | `vote` | 14, 97 |
| `post` (notices) | 24, 98 | | `schedule` | 13, 96 |
| `call` | 51, 52 | | `system` (join/leave) | 0 |
| `custom` (rich cards) | 71 | | `notification` (AlimTalk) | 72 |
| `contact`, `gift`, `kakaolink`, `avatar`, `lottery`, `profile`, `nudge`, `search`, `plus_friend` | 4, 7, 9, 11, 15, 17, 21, 23, 81–83 | | `unknown` | anything else |

A code with 16384 (`0x4000`) added is the same type, deleted for everyone.

코드에 16384(`0x4000`)가 더해진 메시지는 같은 종류의 "모두에게서 삭제된" 메시지입니다.

### Send / 전송

```bash
kakaocli send "chat name" "message"    # Send to a chat
kakaocli send --me _ "message"         # Send to self-chat (나와의 채팅)
kakaocli send --dry-run "name" "msg"   # Preview without sending
```

How the chat is chosen, so a message never goes to the wrong chat:

1. A chat whose name is **exactly** the argument wins.
2. Otherwise a substring is accepted only if it matches **one** chat. If several match (e.g. `민수` matches `민수 가족방` and `민수 친구들`), `send` fails and lists them, so retry with the exact name.
3. After the chat window opens, its title must equal the matched chat's name, or the window is closed and nothing is sent.

전송 대상은 이렇게 고릅니다: 이름이 정확히 같은 방이 우선이고, 부분 일치는 한 방에만 걸릴 때만 허용합니다. 여러 방에 걸리면 후보 목록과 함께 실패합니다. 창이 열린 뒤 제목이 다르면 아무것도 보내지 않고 창을 닫습니다.

### Sync / 동기화

```bash
kakaocli sync --follow                              # NDJSON stream of new messages
kakaocli sync --follow --interval 1                  # Poll every 1 second
kakaocli sync --follow --webhook http://localhost:8080/kakao  # POST to webhook
```

`sync` polls the database (default every 2s) and prints each new message once. Outgoing messages that KakaoTalk has not yet confirmed with the server are skipped until they get their real `logId`.

`sync`는 DB를 주기적으로(기본 2초) 확인해 새 메시지를 한 번씩 출력합니다. `--webhook`을 주면 출력 대신 해당 URL로 POST합니다.

See [AGENTS.md](AGENTS.md) for AI agent integration instructions.

### Harvest / 수집

```bash
kakaocli harvest                   # Capture display names for all chats
kakaocli harvest --scroll          # Also load older message history
kakaocli harvest --scroll --top 20 # Process top 20 most recent chats
kakaocli harvest --dry-run         # Preview without changes
```

The harvest command iterates through your chat list to:
1. Capture **display names** from the UI (many group chats show `(unknown)` in the database)
2. With `--scroll`: open each chat, scroll to top, click "View Previous Chats" to load older messages
3. Auto-dismiss **Talk Drive Plus paywall** popups
4. Save metadata to `~/.kakaocli/metadata.json`

Chats with unread messages are skipped to avoid marking them as read.

### Login / 로그인

```bash
kakaocli login                                       # Store credentials (interactive)
kakaocli login --email user@example.com --password pw # Non-interactive
kakaocli login --status                               # Check status
kakaocli login --clear                                # Remove credentials
```

When you run `send`, `sync`, or any command that needs KakaoTalk, the tool automatically launches the app, detects the login screen, fills credentials, and waits for login to complete.

## AI Integration / AI 연동

kakaocli is designed to work with AI coding assistants and agents. Every read command outputs structured JSON, and the tool handles KakaoTalk's full lifecycle automatically (launch, login, window management).

### Claude Code

Add kakaocli as a skill in your project's `CLAUDE.md`:

```markdown
## KakaoTalk Integration

Use `kakaocli` to read and send KakaoTalk messages:
- `kakaocli chats --json` — list all chats
- `kakaocli messages --chat "name" --json` — read messages
- `kakaocli history --chat-id ID --limit 100` — page through a whole chat (pass `cursor` to `--before`)
- `kakaocli search "keyword" --json` — search messages
- `kakaocli send "name" "message"` — send a message
- `kakaocli send --me _ "message"` — send to self-chat (safe for testing)
```

Or copy the skill file directly:

```bash
# Copy the skill definition to your project
cp skills/kakaocli/SKILL.md /path/to/your/project/.claude/skills/
```

Claude Code can then read your KakaoTalk messages, search conversations, and send messages on your behalf.

### Cursor / Windsurf / Other AI Editors

Add to your project rules or `.cursorrules`:

```
You have access to kakaocli for KakaoTalk messaging.
Run `kakaocli chats --json` to list chats.
Run `kakaocli messages --chat "name" --since 1d --json` to read messages.
Run `kakaocli send "name" "message"` to send messages.
Always use --me flag when testing: `kakaocli send --me _ "test"`.
Always ask for confirmation before sending messages to other people.
```

### Webhooks & Real-time Agents

For agents that need to react to incoming messages in real-time:

```bash
# Stream new messages as NDJSON (pipe to your agent)
kakaocli sync --follow | your-agent-processor

# Or POST to a webhook endpoint
kakaocli sync --follow --webhook http://localhost:8080/kakao
```

Each new message is delivered as a JSON object:

```json
{"type": "message", "log_id": 456, "chat_id": 123, "chat_name": "지수", "sender_id": 789, "sender": "김지수", "text": "안녕!", "message_type": 1, "message_type_name": "text", "deleted": false, "timestamp": "2026-02-20T09:15:00Z", "is_from_me": false}
```

With `--webhook`, messages are POSTed in batches as a JSON array.

### OpenClaw

A kakaocli [skill definition](skills/kakaocli/SKILL.md) is included for use with [OpenClaw](https://github.com/nichochar/open-claw) or similar skill registries.

See [AGENTS.md](AGENTS.md) for detailed integration instructions including credential setup, lifecycle management, and error handling.

## How It Works / 동작 원리

kakaocli reads KakaoTalk's local SQLCipher-encrypted database in **read-only mode** — it never modifies the database. For sending messages and UI interactions, it uses macOS Accessibility APIs (AXUIElement) to automate the native KakaoTalk client.

kakaocli는 카카오톡의 로컬 SQLCipher 암호화 데이터베이스를 **읽기 전용 모드**로 읽습니다 — 데이터베이스를 절대 수정하지 않습니다. 메시지 전송 및 UI 상호작용에는 macOS 접근성 API(AXUIElement)를 사용하여 네이티브 카카오톡 클라이언트를 자동화합니다.

The database key is derived from your Mac's hardware UUID and your KakaoTalk userId. Current KakaoTalk only stores the userId as a SHA-512 hash, so kakaocli recovers it once by search and caches it in `~/.kakaocli/userid`. The cache is ignored automatically when you log in with a different account; delete the file to force a fresh search.

DB 키는 Mac 하드웨어 UUID와 카카오톡 userId로 만듭니다. 최신 카카오톡은 userId를 SHA-512 해시로만 저장하므로 처음 한 번 찾아서 `~/.kakaocli/userid`에 캐시합니다. 다른 계정으로 로그인하면 캐시는 자동으로 무시됩니다.

Files kakaocli writes / kakaocli가 쓰는 파일:

| Path | Contents |
|------|----------|
| `~/.kakaocli/userid` | Cached userId |
| `~/.kakaocli/metadata.json` | Chat names captured by `harvest` |

## Known Limitations / 알려진 제한 사항

> [!WARNING]
> **macOS only.** This tool works exclusively with KakaoTalk for Mac. It does not support Windows, mobile, or web versions.

- **Incomplete message history.** KakaoTalk Mac only syncs messages from the server when you open a chat. If you haven't opened a chat on your Mac in a while (or ever), older messages won't be in the local database. Use `kakaocli harvest --scroll` to trigger loading older history, but this is limited by KakaoTalk's own sync behavior and the Talk Drive Plus paywall.
- **Group chat names may show as `(unknown)`.** The database doesn't always store display names for group chats. Run `kakaocli harvest` to capture names from the UI.
- **Sending requires KakaoTalk to be running.** Read commands work without the app open, but `send`, `sync`, and `harvest` need the KakaoTalk window. kakaocli launches and logs in automatically if credentials are stored.
- **One Mac at a time.** KakaoTalk only allows one Mac logged in per account.
- **Media and non-text messages.** Every message gets a type name (photo, file, reply, emoticon, …), and `history` includes attachment metadata and the local file path when the file was downloaded. Media itself is not downloaded or rendered.

> [!WARNING]
> **macOS 전용.** 이 도구는 카카오톡 Mac 버전에서만 작동합니다.

- **불완전한 메시지 기록.** 카카오톡 Mac은 채팅을 열어야 서버에서 메시지를 동기화합니다. Mac에서 오래 열지 않은 채팅은 이전 메시지가 로컬 데이터베이스에 없을 수 있습니다. `kakaocli harvest --scroll`로 이전 메시지 로드를 시도할 수 있지만, 카카오톡 자체 동기화 및 톡드라이브 플러스 페이월에 의해 제한됩니다.
- **그룹 채팅 이름이 `(unknown)`으로 표시될 수 있습니다.** `kakaocli harvest`를 실행하여 UI에서 이름을 수집하세요.
- **전송 시 카카오톡 실행 필요.** 읽기 명령은 앱 없이 작동하지만, `send`, `sync`, `harvest`는 카카오톡 창이 필요합니다.
- **계정당 Mac 1대.** 카카오톡은 계정당 하나의 Mac만 로그인을 허용합니다.
- **미디어 및 비텍스트 메시지.** 모든 메시지에 종류(사진, 파일, 답장, 이모티콘 등)가 표시되고, `history`는 첨부파일 정보와 (Mac에 받아 둔 경우) 로컬 파일 경로를 줍니다. 미디어 자체를 내려받거나 보여주지는 않습니다.

## Disclaimer

> **This project is not affiliated with, endorsed by, or associated with Kakao Corp. in any way.**
>
> "KakaoTalk" and "카카오톡" are trademarks of Kakao Corp. This tool is an independent, unofficial project.
>
> **What this tool does:**
> - Reads the KakaoTalk local database on your own machine (read-only, never modifies it)
> - Automates the native KakaoTalk Mac client via standard macOS Accessibility APIs
>
> **What this tool does NOT do:**
> - Does not reverse-engineer or reimplement the KakaoTalk protocol (LOCO)
> - Does not call any Kakao APIs or servers
> - Does not decompile or modify the KakaoTalk application
> - Does not bypass any authentication or security mechanisms
>
> This tool accesses only your own data stored locally on your own computer. Use responsibly and at your own risk. The authors are not responsible for any consequences of using this software, including but not limited to account restrictions by Kakao.

## 면책 조항

> **이 프로젝트는 카카오와 제휴, 보증, 또는 관련이 없습니다.**
>
> "KakaoTalk" 및 "카카오톡"은 카카오의 상표입니다. 이 도구는 독립적인 비공식 프로젝트입니다.
>
> **이 도구가 하는 것:**
> - 사용자의 컴퓨터에 있는 카카오톡 로컬 데이터베이스를 읽기 전용으로 읽습니다
> - 표준 macOS 접근성 API를 통해 카카오톡 Mac 클라이언트를 자동화합니다
>
> **이 도구가 하지 않는 것:**
> - 카카오톡 프로토콜(LOCO)을 역분석하거나 재구현하지 않습니다
> - 카카오 API나 서버를 호출하지 않습니다
> - 카카오톡 애플리케이션을 디컴파일하거나 수정하지 않습니다
>
> 이 도구는 사용자 본인의 컴퓨터에 저장된 본인의 데이터에만 접근합니다. 책임감 있게 사용하시기 바랍니다. 카카오의 계정 제한 등 이 소프트웨어 사용으로 인한 결과에 대해 저자는 책임지지 않습니다.

## Credits / 크레딧

Developed by **[Brian ByungHyun Shin](https://github.com/brianshin22)** at **[Silver Flight Group](https://github.com/silver-flight-group)**.

Database decryption approach based on research by [blluv](https://gist.github.com/blluv/8418e3ef4f4aa86004657ea524f2de14).

Inspired by [wacli](https://github.com/steipete/wacli) by Peter Steinberger — a similar CLI tool for WhatsApp on Mac.

Built with [Claude Code](https://claude.ai/code).

## License

MIT License. Copyright (c) 2026 Silver Flight Group, LLC. See [LICENSE](LICENSE) for details.

## [Changelog](CHANGELOG.md)
