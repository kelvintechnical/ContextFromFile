# Context from File (R · Python · C#)

**Read an external `.txt` file from disk, inject it into the system prompt, and build a reconfigurable chatbot in R, Python, and C#.**

> Part of the [Trilingual Coding Compounding Series](https://github.com/kelvintechnical?tab=repositories&q=compounding). Each project teaches the same milestone in **R → Python → C#** simultaneously.

---

## What This Project Teaches

| Skill | Purpose |
|-------|---------|
| **File I/O** | Read `.txt` files from disk with safe path handling |
| **String Injection** | Concatenate file contents into the system prompt before the chat loop |
| **Configurability** | Swap bot “personality” by changing `context.txt`, not application code |
| **UTF-8 Encoding** | Handle multi-byte characters safely across Windows, macOS, and Linux |
| **Separation of Concerns** | Keep external data (context) separate from source code |

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

- Load API key from environment (and optional `.env` / user secrets where configured)
- Build HTTP POST request with headers and JSON payload
- Parse JSON response to extract assistant text
- Seed `messages` with a system-role prompt
- Infinite conversation loop with exit condition
- Append user message before the API call
- Pass full message history to the API each turn
- Append assistant reply after each turn

---

## New Skills Introduced in Project 4

### 1. File I/O (read `.txt` from disk)

**Python** (`Python/chatbot.py` — resolves repo root from `__file__`, then opens with UTF-8):

```python
from pathlib import Path

repo_root = Path(__file__).resolve().parent.parent
context_path = repo_root / "context.txt"
if not context_path.is_file():
    raise FileNotFoundError(f"Context file not found: {context_path}")

with open(context_path, encoding="utf-8") as f:
    file_context = f.read()
```

**R** (`R/chatbot.R` — `Rscript R/chatbot.R` from repo root; path joins from script directory):

```r
args <- commandArgs(trailingOnly = FALSE)
file_flags <- args[startsWith(args, "--file=")]
script_dir <- if (length(file_flags)) {
  dirname(normalizePath(sub("^--file=", "", file_flags[1])))
} else {
  getwd()
}
context_path <- normalizePath(file.path(script_dir, "..", "context.txt"), mustWork = TRUE)
if (!file.exists(context_path)) {
  stop(paste("Context file not found:", context_path))
}
file_context <- paste(
  readLines(context_path, encoding = "UTF-8", warn = FALSE),
  collapse = "\n"
)
```

**C#** (`CSharp/Program.cs` — `context.txt` is copied beside the build output via `CSharp.csproj`):

```csharp
using System.Text;

var contextPath = Path.Combine(AppContext.BaseDirectory, "context.txt");
if (!File.Exists(contextPath))
    throw new FileNotFoundException($"Context file not found: {contextPath}");

var fileContext = File.ReadAllText(contextPath, Encoding.UTF8);
```

**Key gotcha:** Always specify UTF-8 explicitly (`encoding="utf-8"` in Python, `encoding = "UTF-8"` in `readLines`, `Encoding.UTF8` in C#). On Windows, default encodings are often legacy code pages and will corrupt non-ASCII text.

### 2. Safe path handling

| Language | Pattern | Why |
|----------|---------|-----|
| Python | `Path(__file__).resolve().parent.parent / "context.txt"` | Stable path relative to the script, not the shell’s cwd |
| R | `file.path(script_dir, "..", "context.txt")` + `normalizePath` | Cross-platform separators; works with `Rscript R/chatbot.R` |
| C# | `Path.Combine(AppContext.BaseDirectory, "context.txt")` | Resolves next to the published binary after MSBuild copies the file |

### 3. String injection into the system prompt

```python
persona = "You are a helpful assistant that stays faithful to the supplied context."
system_prompt = f"{persona}\n\n--- Context from file ---\n{file_context}"
```

The file content becomes part of the **persistent** system instruction—it shapes behavior for the whole session, not a single user turn.

### 4. Why context belongs in the `system` role, not the `user` role

| Role | Effect | Typical use |
|------|--------|-------------|
| `system` | Stable instructions for the whole conversation | Persona, policy, loaded knowledge |
| `user` | One turn in the thread | The live question for this round |

File-backed context is **standing instruction**, so it belongs in the system prompt (then the memory loop appends alternating `user` / `assistant` turns as in Project 3).

---

## Project structure

```text
ContextFromFile/
├── R/
│   └── chatbot.R
├── Python/
│   ├── chatbot.py
│   └── requirements.txt
├── CSharp/
│   ├── CSharp.csproj
│   └── Program.cs
├── context.txt                 # External context (edit without touching code)
├── .env.example
├── .gitignore
├── REPEATABLE_PROMPT.md        # Full series rules + project list (1–15)
└── README.md
```

---

## Sample `context.txt`

The repository includes a starter **starship Meridian** briefing. Replace it entirely—for example with the **fortune teller** sample below—to see how behavior changes without code edits:

```text
You are a cryptic fortune teller who speaks in riddles.
When the user asks a question, respond with exactly one short fortune (1–2 sentences)
that hints at the answer but never states it directly.
Always end with: "The stars remain silent on further details."
```

---

## Running each language

**Prerequisite:** `OPENAI_API_KEY` in your environment, in a `.env` file at the **repository root** (Python/R), and/or in **.NET user secrets** for C# (`dotnet user-secrets set "OPENAI_API_KEY" "..."` from `CSharp/`).

### Python

```powershell
python Python/chatbot.py
```

(Recommended: create `Python/.venv`, activate it, then `pip install -r Python/requirements.txt`.)

### R

```powershell
Rscript R/chatbot.R
```

(Run from repo root so paths and optional `.env` resolve.)

### C#

```powershell
dotnet run --project CSharp/CSharp.csproj
```

---

## What this unlocks: progression toward RAG

| Stage | What happens |
|-------|----------------|
| **Project 4** (this repo) | Load one static `.txt` into the system prompt |
| **Project 5** (PDF_Reader_Bot) | Extract text from PDFs, inject the same way |
| Later | Multiple documents, ranking, top-K chunks into the prompt |
| **RAG-style systems** | Query → retrieve → inject context → API call |

The **plumbing** (read text → merge into system message → multi-turn history) stays the same; only the **source** of the text changes.

---

## Next project

**[PDF_Reader_Bot](https://github.com/kelvintechnical/PDFReaderBot)** — parse PDFs and feed them into context like a supercharged `.txt` file.

---

## Environment setup

### Prerequisites

- Python **3.10+**
- R **4.x+**
- .NET SDK **10.x** (this C# project targets `net10.0`)
- **OpenAI** API access; key as `OPENAI_API_KEY` (not Anthropic in this repo)

### Install dependencies

**Python**

```powershell
cd Python
pip install -r requirements.txt
```

**R**

```r
install.packages(c("httr2", "jsonlite", "dotenv"), repos = "https://cloud.r-project.org")
```

**C#**

```powershell
cd CSharp
dotnet restore
dotnet user-secrets set "OPENAI_API_KEY" "your-key-here"
```

---

## Terminal setup (series convention)

```powershell
python --version                        # 3.10+
Rscript --version                       # 4.x+
dotnet --version                        # 10.x
```

See `REPEATABLE_PROMPT.md` for the full non-negotiable series rules, the **Projects 1–15** roadmap, and the **cross-language equivalency table** through Project 4.

---

## Cross-language equivalency (Projects 1–4)

| Concept | Python | R | C# |
| ------- | ------ | - | -- |
| Import library | `import requests`, `from dotenv import load_dotenv` | `library(httr2)`, `library(jsonlite)`, `library(dotenv)` | `HttpClient`, `Microsoft.Extensions.Configuration`, `System.Text.Json` |
| Read env / secrets | `load_dotenv(...)` then `os.getenv("OPENAI_API_KEY")` | `dotenv::load_dot_env()` then `Sys.getenv("OPENAI_API_KEY")` | `configuration["OPENAI_API_KEY"]` |
| API endpoint | `base_url` | `base_url` | `baseUrl` |
| Chat API call | `call_openai(messages)` | `call_openai(messages)` | `CallOpenAI(http, apiKey, baseUrl, messages)` |
| System prompt variable | `system_prompt` | `system_prompt` | `systemPrompt` |
| Read UTF-8 file | `open(path, encoding="utf-8")` | `readLines(..., encoding = "UTF-8")` + `paste(..., collapse = "\n")` | `File.ReadAllText(path, Encoding.UTF8)` |

---

## Skills repeated from previous projects

**Python:** env / `.env` key, `requests` POST + JSON, parse response, `system_prompt` + seed `messages`, loop + `quit`, append user / full history / assistant.

**R:** env / `.env` key, `httr2` POST + JSON, `jsonlite` parse, `system_prompt` + seed `messages`, loop + `quit`, append user / full history / assistant.

**C#:** `IConfiguration` + user secrets / env, `HttpClient` POST + JSON, `JsonDocument` parse, `systemPrompt` + seed `messages`, loop + `quit`, append user / full history / assistant.

---

## New skill introduced this project

**Python:** `pathlib` + `open(..., encoding="utf-8")`, inject `file_context` into `system_prompt`, comments on system vs user role and external data.

**R:** `file.path` / `normalizePath` + UTF-8 `readLines` + `paste`, inject into `system_prompt`, same rationale in comments.

**C#:** `Path.Combine(AppContext.BaseDirectory, ...)` + `File.ReadAllText(..., Encoding.UTF8)`, build `systemPrompt`, same rationale in comments.

---

## Author

[Kelvin R. Tobias](https://github.com/kelvintechnical) · [kelvinintech.com](https://kelvinintech.com)

Part of the compounding trilingual learning series: **build once, learn three times.**
