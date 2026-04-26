// --- Project 1: Hello LLM ---

using System.Net.Http.Headers;
using System.Reflection;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

// Build configuration from user secrets (dev) and environment variables (CI or shells) so OPENAI_API_KEY is never hard-coded.
var configuration = new ConfigurationBuilder()
    .AddUserSecrets(Assembly.GetExecutingAssembly())
    .AddEnvironmentVariables()
    .Build();

// Load API key from configuration so the same pattern scales to ASP.NET (`config["OPENAI_API_KEY"]` is the canonical accessor).
var apiKey = configuration["OPENAI_API_KEY"]
    ?? throw new InvalidOperationException("Set OPENAI_API_KEY via user secrets (`dotnet user-secrets set ...`) or your environment before running.");

// Central place for the API endpoint so you can swap providers or versions later.
var baseUrl = "https://api.openai.com/v1/chat/completions";

static string CallOpenAI(HttpClient http, string apiKey, string baseUrl, List<Dictionary<string, string>> messages)
{
    // Build HTTP POST with JSON body, send chat history, return assistant text from JSON.
    using var request = new HttpRequestMessage(HttpMethod.Post, baseUrl);
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

    var payload = new { model = "gpt-4o-mini", messages };
    var json = JsonSerializer.Serialize(payload);
    request.Content = new StringContent(json, Encoding.UTF8, "application/json");

    var response = http.Send(request);
    response.EnsureSuccessStatusCode();
    using var doc = JsonDocument.Parse(response.Content.ReadAsStringAsync().GetAwaiter().GetResult());
    // Parse JSON response: the model reply lives under choices[0].message.content.
    return doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "";
}

// --- Project 2: Persona Bot ---

static void RunChat(HttpClient http, string apiKey, string baseUrl, string systemPrompt)
{
    // Seed the messages list with the system role so the model always sees persona + file context first.
    var messages = new List<Dictionary<string, string>>
    {
        new() { ["role"] = "system", ["content"] = systemPrompt }
    };

    // Infinite conversation loop with exit condition (user types quit).
    Console.WriteLine("Chat with context loaded. Type 'quit' to exit.\n");

    while (true)
    {
        Console.Write("You: ");
        var userText = Console.ReadLine()?.Trim() ?? "";
        if (string.Equals(userText, "quit", StringComparison.OrdinalIgnoreCase))
            break;
        if (string.IsNullOrEmpty(userText))
            continue;

        // --- Project 3: Chatbot with Memory ---

        // Append user message to messages before calling API so this turn is part of the thread.
        messages.Add(new Dictionary<string, string> { ["role"] = "user", ["content"] = userText });

        // Pass full messages history on every API call (CallOpenAI receives the whole list).
        var assistantReply = CallOpenAI(http, apiKey, baseUrl, messages);

        // Append assistant reply to messages after each turn so the next loop carries memory forward.
        messages.Add(new Dictionary<string, string> { ["role"] = "assistant", ["content"] = assistantReply });

        Console.WriteLine($"Assistant: {assistantReply}\n");
    }
}

// --- Project 4: Context from a File (new skills at bottom of file) ---

using var httpClient = new HttpClient();

// Path handling: place context.txt next to the built binary (copied via csproj) so resolution works across dev and publish.
var contextPath = Path.Combine(AppContext.BaseDirectory, "context.txt");

// File I/O: read external knowledge once; UTF-8 avoids mojibake on Windows when the file has non-ASCII text.
// Windows gotcha: File.ReadAllText without Encoding can use a legacy Windows code page and corrupt UTF-8—always pass UTF8.
var fileContext = File.ReadAllText(contextPath, Encoding.UTF8);

// String injection: merge file text into the system string before we build the conversation.

// Define a system persona string (base behavior before we layer file context on top).
var persona = "You are a helpful assistant that stays faithful to the supplied context.";
var systemPrompt = $"{persona}\n\n--- Context from file ---\n{fileContext}";

// Prompt engineering: system role sets stable instructions and knowledge boundaries for the model;
// putting this in the user role would make it look like a turn the human "said," which confuses multi-turn memory and priority.

// Separation of concerns: editing context.txt changes behavior without editing this source file.

RunChat(httpClient, apiKey, baseUrl, systemPrompt);
