library(dotenv) # Provides load_dot_env() so .env variables become visible to Sys.getenv()
library(httr2) # Modern HTTP client: build request, set JSON body, perform POST in a readable pipe

# If you always run from repo root: load_dot_env(file = ".env")
# If you run from R/: point at the parent folder's .env

# --- Step 1: Load API key from environment (Project 1) ---
load_dot_env(file = file.path("..", ".env")) # Loads OPENAI_API_KEY from project root without hardcoding the key
api_key <- Sys.getenv("OPENAI_API_KEY") # Reads the key into api_key for Authorization headers

# --- Step 2: Define base_url and headers (Project 1) ---
base_url <- "https://api.openai.com/v1/chat/completions" # Chat Completions API route; change here if you ever switch endpoints
auth_header <- paste("Bearer", api_key) # Full Authorization header OpenAI expects (Bearer + space + key from Step 1)

# --- Step 3: Build HTTP POST with JSON payload (Project 1) ---
call_openai <- function(messages) {
  request(base_url) |>
    req_headers(
      Authorization = auth_header, # Step 2: proves who we are to OpenAI
      `Content-Type` = "application/json" # Explicit JSON; matches what req_body_json sends
    ) |>
    req_body_json(list(
      model = "gpt-4o-mini", # Cheap, capable chat model; change if your org uses another name
      messages = messages # Full conversation history (system/user/assistant) as the API expects
    )) |>
    req_perform() # Sends the POST and returns the raw response object for Step 4 parsing
}

# --- Step 4: Parse JSON response, extract assistant text (Project 1) ---
extract_assistant_text <- function(response) {
  data <- resp_body_json(response) # Decode JSON body to an R list
  data$choices[[1]]$message$content # First completion's assistant message text
}

# --- Step 5: Define system_prompt string (Project 2) ---
system_prompt <- paste0(
  "You are my software engineering instructor. ",
  "You will help me learn how to program in any language.",
  "You will help me understand the concepts of programming. Lets get started by you explaining the syntax in human readable terms.",
  "Please explain the syntax in a way that is easy to understand and follow.",
  "Ask if I understand at each step and if not, explain again in a way that is easy to understand and follow."
)

# --- Step 6: Seed messages with system role (Project 2) ---
# CONCEPT: The transcript starts with the rules — messages is what you send every turn;
# role = "system" makes the model treat system_prompt as global policy before any user text.
messages <- list(list(role = "system", content = system_prompt)) # Initial transcript: policy first, before any user input

# --- Step 7: Build conversation loop with exit condition (Project 3) ---
# CONCEPT: repeat { ... } runs many turns until break (EOF or "quit").
repeat {
  # --- Step 8: Read user input from stdin (Project 3) ---
  # CONCEPT: stdin is keyboard when interactive, or piped lines when testing; warn=FALSE reduces EOF noise;
  # encoding="UTF-8" helps on Windows with non-ASCII text.
  cat("\nYou: ") # Prompt so it is obvious the program is waiting for input

  user_input <- readLines(
    con = "stdin", # Standard input from the terminal
    n = 1, # One line per turn
    warn = FALSE, # Fewer warnings when the stream ends (EOF) without a final newline
    encoding = "UTF-8" # Prefer UTF-8 so pasted/special characters match your editor and API text
  )

  if (length(user_input) == 0) {
    break # EOF (e.g. Ctrl+Z then Enter on Windows): exit before subscripting user_input
  }

  user_line <- trimws(user_input[[1]]) # Safe scalar string for quit check and for appending to messages

  if (tolower(user_line) == "quit") {
    break # Explicit exit word
  }

  # --- Step 9: Append user message to messages before the API call (Project 3) ---
  # CONCEPT: The API only sees what is in messages; append preserves full history.
  messages <- append(
    messages,
    list(list(role = "user", content = user_line)) # Record this turn's user text before the POST
  )

  # --- Step 10: Call API and append assistant reply (Project 3) ---
  # CONCEPT: Send full history, then store the assistant reply so the next turn has context (no amnesia).
  response <- call_openai(messages) # Full transcript (system + user/assistant turns) in one POST
  assistant_text <- extract_assistant_text(response) # Plain string from choices[[1]]$message$content
  cat("\nAssistant:", assistant_text, "\n") # Echo reply to the terminal

  messages <- append(
    messages,
    list(list(role = "assistant", content = assistant_text)) # Persist reply for the next user turn
  )
}

# --- Steps 11–12 (Project 4 — next): Read context.txt with safe path + UTF-8; inject into system_prompt
# before Step 6's messages <- ... (or move messages seeding below file load + injection).


# Step 11 — Read context.txt from disk (safe path + UTF-8) (Project 4, new)
# Build a path to context.txt next to your project (e.g. with file.path("..", "context.txt") when you run from R/), so it doesn’t depend on the current working directory in a fragile way.
# Read the file as UTF-8 and turn it into one string (e.g. paste(readLines(..., warn = FALSE), collapse = "\n"), with encoding handled as you prefer for your R version).
# Store that string in something like context_text (or a name you keep consistent with your README).

context_path <- file.path("..", "context.txt")   # # Stable path from R/ to project root; avoids hardcoding a drive letter
context_lines <- readLines(context_path, warn = FALSE, encoding = "UTF-8") #  # One string per line; UTF-8 for Windows/editor consistency
context_text <- paste(context_lines, collapse = "\n") # # Single block of text to inject into the system prompt in Step 12

# Rscript -e "p <- file.path('..','context.txt'); x <- paste(readLines(p, warn=FALSE, encoding='UTF-8'), collapse='\n'); cat(nchar(x) > 0, '\n')"

# Step 13: Inject file contents into system_prompt BEFORE seeding messages 
# (Project 4 origin)
# # ========================================= 
# CONCEPT: messages captures whatever system_prompt is at the moment you create it.
# # If you seed messages first, the model never sees your file 
# context.
# # So you must: 
# read context_text → build final system_prompt → then create messages.
# # In your chatbot.R, 
# this Step 13 code must appear right before the line
#  that seeds messages (your current Step 6).

#TASK: Save a copy of the original instructions before 
#adding the file context.
#WHY: We're about to overwrite system_prompt; without a backup we lose the base persona for any
#later rebuild
#DEPENDS ON: 'system_prompt'  from step 5 (Persona Bot)
#SYNTAX: Use '<-' to assign the current string into a new variable name. 
base_system_prompt <- system_prompt
# Python: base_system_prompt = system_prompt
# C# : string baseSystemPrompt = systemPrompt;


# Task: Create a system prompt by adding the context file text underneath the original instructions.
# WHY: The model only 'knows' what is in its system prompt -- injecting the file is how external context becomes useable. 
# DEPENDS ON: 'base_system_prompt' from line above, + 'context_text' from step 12 (file read)
# SYNTAX: paste0() concactenates strings with no separator; "\n\n" inserts a blank line for readability.

system_prompt <- paste0(base_system_prompt, "\n\n", context_text)
# Python: system_prompt = base_system_prompt + "\n\n" + context_text
# C#: systemPrompt = baseSystemPrompt + "\n\n" + contextText;


messages <- list(
  list(
    role = "system", 
    "content" = system_prompt
  )
)
# Python: messages = [{role: "system", "content": system_prompt}]
# C#: var messages = new List<Dictonary<string,string>> {new () {["role"] = "system", ["content"]=systemPrompt}}; 


# Step 14: Verify the context is actually being sent 
# Project 4 wrap-up)
# ========================================= 
# CONCEPT: “It ran” isn’t proof the model saw your file — 
# you must verify the system message contains the injected text.

#TASK: Confirm the system message message contains the injected context text.
#WHY: This proves step 13 worked and the API will receive the file context.
#DEPENDS ON: 'messags' seeded after rebuilding 'system_prompt' (Steps 12-13)
#SYNTAX: messages[[1]] selects the first message; '$content' pulls the content field; cat() prints it.
cat(messages[[1]]$content, "\n")
# Python: print(message[0]["content"])
# C#: Console.WriteLine(message[0]["content"])


#TASK: Ask a question tat only the context file can answer.
# WHY: This proves the model has the file context available. 
# DEPENDS ON: 'context_text' containing real, specific info (Step 12) + injected into 'system_prompt' (Step 13).
# SYNTAX: Type a prompt into your exisiting repeat/readLines Loop and look for 
# file-specific details in the reply

user_line <- "What specific facts did you learn from context.txt? Quote one line and express your intrepretation of it."

# Step 15: Run the full chatbot loop and confirm context affects answers 
# (Project 4 completion)
# ========================================= 
# CONCEPT: Now that system_prompt includes the file, 
# the running loop should consistently answer using that context every turn.

