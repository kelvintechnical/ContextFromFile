using System; // WHAT: Core .NET types like Exception and Console. WHY: We throw on missing keys and print output. DEPENDS ON: Step 1 (throw) + Step 4 (Console.WriteLine).
using System.Net.Http; // WHAT: HttpClient/HttpRequestMessage/HttpMethod. WHY: Required to send HTTP requests. DEPENDS ON: Step 3 (client + request).
using System.Net.Http.Headers; // WHAT: AuthenticationHeaderValue. WHY: Cleanly sets the Authorization header as "Bearer <key>". DEPENDS ON: Step 3 (req.Headers.Authorization).
using System.Text; // WHAT: Encoding.UTF8. WHY: Ensures JSON body is encoded as UTF-8. DEPENDS ON: Step 3 (StringContent).
using System.Text.Json; // WHAT: JsonSerializer + JsonDocument. WHY: Serialize request JSON + parse response JSON. DEPENDS ON: Step 3 (Serialize) + Step 4 (Parse/extract).
using System.Threading.Tasks; // WHAT: Async/await support for top-level statements. WHY: Allows awaiting HTTP calls in this file. DEPENDS ON: Step 4 (await SendAsync/ReadAsStringAsync).
using Microsoft.Extensions.Configuration; // WHAT: ConfigurationBuilder + IConfiguration. WHY: Reads User Secrets (OPENAI_API_KEY) safely. DEPENDS ON: Step 1 (config + apiKey).

// ============================================================
// Step 1: Load API key from environment (User Secrets) (Project 1 origin)
// ============================================================

// TASK: Build a configuration object that knows how to read values from this project's User Secrets store.
// WHY: This wires up the mechanism for fetching OPENAI_API_KEY later (without hardcoding it in source code).
// DEPENDS ON: `dotnet user-secrets init` (writes UserSecretsId into .csproj) + `dotnet user-secrets set "OPENAI_API_KEY" "..."`.
// SYNTAX: `new ConfigurationBuilder()` creates the builder; `.AddUserSecrets<Program>()` locates this project's secrets; `.Build()` returns IConfiguration.
var config = new ConfigurationBuilder()
  .AddUserSecrets<Program>()
  .Build();
// PYTHON: load_dotenv(override=True); api_key = os.getenv("OPENAI_API_KEY")
// R:      load_dot_env(file = file.path("..", ".env")); api_key <- Sys.getenv("OPENAI_API_KEY")

// TASK: Read the OpenAI API key into a variable for later HTTP headers.
// WHY: The key is required to authenticate requests (Authorization: Bearer ...).
// DEPENDS ON: `config` created above + User Secrets containing "OPENAI_API_KEY".
// SYNTAX: `config["OPENAI_API_KEY"]` reads a string; `?.Trim()` removes whitespace; `?? throw` fails fast if missing.
string apiKey = config["OPENAI_API_KEY"]?.Trim() ?? throw new Exception("OPENAI_API_KEY is missing");
// PYTHON: api_key = os.getenv("OPENAI_API_KEY")
// R:      api_key <- Sys.getenv("OPENAI_API_KEY")


// ============================================================
// Step 2: Define base URL / endpoint + auth header (Project 1 origin)
// ============================================================

// TASK: Create an HTTP client we can use to send requests.
// WHY: HttpClient is the standard way to send HTTP requests in .NET.
// DEPENDS ON: Nothing.
// SYNTAX: `new HttpClient()` constructs the client instance.
var client = new HttpClient();
// PYTHON: import requests
// R:      library(httr2)

// TASK: Store the Chat Completions endpoint URL in a variable.
// WHY: Keeping the URL in one place makes it easy to change later and avoids typos.
// DEPENDS ON: Nothing (this is a constant string).
// SYNTAX: A normal C# string variable assignment.
string baseUrl = "https://api.openai.com/v1/chat/completions";
// PYTHON: base_url = "https://api.openai.com/v1/chat/completions"
// R:      base_url <- "https://api.openai.com/v1/chat/completions"

// TASK: Build the Authorization header value using your API key.
// WHY: OpenAI expects `Authorization: Bearer <key>` on requests.
// DEPENDS ON: `apiKey` from Step 1.
// SYNTAX: String interpolation (`$"..."`) embeds apiKey into the header value.
string authHeader = $"Bearer {apiKey}";
// PYTHON: auth_header = f"Bearer {api_key}"
// R:      auth_header <- paste("Bearer", api_key)


// ============================================================
// Step 3: Build HTTP POST with JSON payload (Project 1 origin)
// ============================================================

// TASK: Build the JSON payload with model + messages.
// WHY: The API expects a JSON body with `model` and `messages` fields.
// DEPENDS ON: For now we send one hardcoded user message; later you’ll send the evolving `messages` history.
// SYNTAX: An anonymous object becomes JSON via `JsonSerializer.Serialize(payload)`.
var payload = new
{
  model = "gpt-4o-mini",
  messages = new object[]
  {
    new { role = "user", content = "Hello, how are you?" }
  }
};
// PYTHON: payload = {"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello, how are you?"}]}
// R:      payload <- list(model="gpt-4o-mini", messages=list(list(role="user", content="Hello, how are you?")))

// TASK: Create the POST request with headers + JSON body.
// WHY: This is the actual HTTP request we send to `baseUrl`.
// DEPENDS ON: `baseUrl` + `apiKey` from Steps 1–2 + `payload` from the block above.
// SYNTAX: `HttpRequestMessage` sets method+url; `Headers.Authorization` sets Bearer; `StringContent` sets JSON body with UTF-8 and content-type.
var req = new HttpRequestMessage(HttpMethod.Post, baseUrl);
req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
req.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
// PYTHON: requests.post(base_url, headers={"Authorization": auth_header}, json=payload)
// R:      request(base_url) |> req_headers(Authorization=auth_header) |> req_body_json(payload) |> req_perform()

// ============================================================
// Step 4: Parse JSON response, extract assistant text (Project 1 origin)
// ============================================================

// TASK: Send the request and read the response body as text.
// WHY: We need the raw JSON string before we can parse it.
// DEPENDS ON: `client` + `req` created above.
// SYNTAX: `await` waits for the async HTTP call; `ReadAsStringAsync()` returns the body string.
var resp = await client.SendAsync(req);
string respText = await resp.Content.ReadAsStringAsync();
// PYTHON: resp = requests.post(...); resp_text = resp.text
// R:      response <- req_perform(...); resp_text <- resp_body_string(response)

// TASK: Parse JSON and extract `choices[0].message.content`.
// WHY: That field contains the assistant reply text.
// DEPENDS ON: `respText` containing valid JSON returned by the API.
// SYNTAX: `JsonDocument.Parse()` parses JSON; `GetProperty()` + `[0]` navigate to the nested value; `GetString()` returns the string.
using var doc = JsonDocument.Parse(respText);
string assistantText = doc.RootElement
  .GetProperty("choices")[0]
  .GetProperty("message")
  .GetProperty("content")
  .GetString() ?? "";
// PYTHON: assistant_text = resp.json()["choices"][0]["message"]["content"]
// R:      assistant_text <- resp_body_json(response)$choices[[1]]$message$content

// TASK: Print the assistant reply.
// WHY: This confirms the end-to-end request + parse pipeline works.
// DEPENDS ON: `assistantText` extracted above.
// SYNTAX: `Console.WriteLine()` writes to standard output.
Console.WriteLine(assistantText);
// PYTHON: print(assistant_text)
// R:      cat(assistant_text, "\n")
