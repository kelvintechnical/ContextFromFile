# Context from File (Project 4) — R

**Read an external `.txt` from disk, inject it into the system prompt, and run a multi-turn chatbot in R.**

This repository currently contains **only the R implementation** (`R/chatbot.R`). The wider series is trilingual (R → Python → C#); see `REPEATABLE_PROMPT.md` for full rules and equivalency across languages.

> Part of the [Trilingual Coding Compounding Series](https://github.com/kelvintechnical?tab=repositories&q=compounding).

---

## What This Project Teaches

| Skill | Purpose |
|-------|---------|
| **File I/O** | Read `.txt` files from disk with safe path handling |
| **String injection** | Concatenate file contents into the system prompt before the chat loop |
| **Configurability** | Swap bot behavior by changing `context.txt`, not only application code |
| **UTF-8 encoding** | Handle multi-byte characters safely (explicit `encoding = "UTF-8"` in `readLines`) |
| **Separation of concerns** | Keep external data (context) separate from source code |

---

## Projects in This Series

| # | Project | Link | Teaches |
|---|---------|------|---------|
| 1 | Hello_LLM | [🔗](https://github.com/kelvintechnical/Hello_LLM) | Authenticate, POST, parse JSON (one-shot) |
| 2 | Persona_Bot | [🔗](https://github.com/kelvintechnical/Persona_Bot) | System persona, conversation loop, exit condition |
| 3 | Chatbot_with_memory | [🔗](https://github.com/kelvintechnical/Chatbot_with_memory) | Message history, append user/assistant roles, full transcript per call |
| **4** | **ContextFromFile** | [🔗](https://github.com/kelvintechnical/ContextFromFile) | **File I/O, path handling, prompt injection** |
| 5 | PDF_Reader_Bot | [🔗](https://github.com/kelvintechnical/PDFReaderBot) | (Coming soon) Extract text from PDFs, inject into context |

---

## Skills Applied from Project 3

Everything from **[Chatbot_with_memory](https://github.com/kelvintechnical/Chatbot_with_memory)** is retyped here in full (not imported): same ideas, fresh code.

- Load API key from environment (with optional `.env` via `dotenv`)
- Build HTTP POST with `httr2`, JSON body, headers
- Parse JSON response to extract assistant text
- Seed `messages` with a system-role prompt
- Infinite conversation loop with exit condition
- Append user message before the API call
- Pass full message history to the API each turn
- Append assistant reply after each turn

---

## New Skills Introduced in Project 4 (R)

### 1. File I/O (read `.txt` from disk)

Run from the `R/` folder so `..` points at the repo root. Example pattern:

```r
context_path <- file.path("..", "context.txt")
context_lines <- readLines(context_path, warn = FALSE, encoding = "UTF-8")
context_text <- paste(context_lines, collapse = "\n")
```

**Key gotcha:** Always pass **`encoding = "UTF-8"`** in `readLines` on Windows so non-ASCII text matches your editor and the API.

### 2. Safe path handling

| Pattern | Why |
|---------|-----|
| `file.path("..", "context.txt")` | Stable relative path when the working directory is `R/` |

### 3. String injection into the system prompt

Build one `system_prompt` string that includes both your instructions and `context_text` (for example with `paste0`), **then** seed `messages` with that combined string. File-backed context is **standing instruction**, so it belongs in the **system** role, not as a fake user turn.

### 4. Why context belongs in the `system` role, not the `user` role

| Role | Effect | Typical use |
|------|--------|-------------|
| `system` | Stable instructions for the whole conversation | Persona, policy, loaded knowledge |
| `user` | One turn in the thread | The live question for this round |

---

## Project structure

```text
ContextFromFile/
├── R/
│   └── chatbot.R
├── context.txt                 # External context (edit without touching code)
├── .gitignore                  # Includes .env (secrets never committed)
├── REPEATABLE_PROMPT.md        # Full series rules + project list (1–15)
└── README.md
```

Create a **`.env`** file at the repo root (same folder as `context.txt`) with `OPENAI_API_KEY=...`. It is ignored by git.

---

## Sample `context.txt`

Replace the starter file to change behavior without code edits. Example:

```text
You are a cryptic fortune teller who speaks in riddles.
When the user asks a question, respond with exactly one short fortune (1–2 sentences)
that hints at the answer but never states it directly.
Always end with: "The stars remain silent on further details."
```

---

## Run (R)

**Prerequisite:** `OPENAI_API_KEY` in a `.env` file at the **repository root** (parent of `R/`).

```powershell
cd R
Rscript chatbot.R
```

Type `quit` to exit. For a quick pipe test:

```powershell
cmd /c "(echo hello& echo quit) | Rscript chatbot.R"
```

---

## Environment setup (R)

- R **4.x+**
- **OpenAI** API access; key as `OPENAI_API_KEY`

```r
install.packages(c("httr2", "jsonlite", "dotenv"), repos = "https://cloud.r-project.org")
```

```powershell
Rscript --version   # expect 4.x+
```

---

## What this unlocks: progression toward RAG

| Stage | What happens |
|-------|----------------|
| **Project 4** (this repo) | Load one static `.txt` into the system prompt |
| **Project 5** (PDF_Reader_Bot) | Extract text from PDFs, inject the same way |
| Later | Multiple documents, ranking, top-K chunks into the prompt |
| **RAG-style systems** | Query → retrieve → inject context → API call |

---

## Next project

**[PDF_Reader_Bot](https://github.com/kelvintechnical/PDFReaderBot)** — parse PDFs and feed them into context like a supercharged `.txt` file.

---

## Cross-language equivalency (Projects 1–4)

Reference for the **series** (Python/C# are not in this repo):

| Concept | Python | R | C# |
| ------- | ------ | - | -- |
| Import library | `import requests`, `from dotenv import load_dotenv` | `library(httr2)`, `library(jsonlite)`, `library(dotenv)` | `HttpClient`, `Microsoft.Extensions.Configuration`, `System.Text.Json` |
| Read env / secrets | `load_dotenv(...)` then `os.getenv("OPENAI_API_KEY")` | `dotenv::load_dot_env()` then `Sys.getenv("OPENAI_API_KEY")` | `configuration["OPENAI_API_KEY"]` |
| API endpoint | `base_url` | `base_url` | `baseUrl` |
| Chat API call | `call_openai(messages)` | `call_openai(messages)` | `CallOpenAI(http, apiKey, baseUrl, messages)` |
| System prompt variable | `system_prompt` | `system_prompt` | `systemPrompt` |
| Read UTF-8 file | `open(path, encoding="utf-8")` | `readLines(..., encoding = "UTF-8")` + `paste(..., collapse = "\n")` | `File.ReadAllText(path, Encoding.UTF8)` |

See `REPEATABLE_PROMPT.md` for the full non-negotiable series rules and the **Projects 1–15** roadmap.

---

## Skills repeated from previous projects

**R:** env / `.env` key, `httr2` POST + JSON, `resp_body_json` parse, `system_prompt` + seed `messages`, loop + `quit`, append user / full history / assistant.

*(Python and C# variants follow the same skill list in other series repos / branches.)*

---

## New skill introduced this project

**R:** `file.path` + UTF-8 `readLines` + `paste`, inject `context_text` into `system_prompt`, comments on system vs user role and external data.

---

## Author

[Kelvin R. Tobias](https://github.com/kelvintechnical) · [kelvinintech.com](https://kelvinintech.com)

Part of the compounding trilingual learning series: **build once, learn three times.**
