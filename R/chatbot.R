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
