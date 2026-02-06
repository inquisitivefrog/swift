#!/usr/bin/env python3

import os
from google import genai
from google.genai import types   # ← note: types (not genai.types)

# AUTH
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("Set GEMINI_API_KEY env var!")

client = genai.Client()  # auto-uses env var

MODEL_NAME = "gemini-2.5-flash"  # ← upgrade here!

# Fetch model info
model_info = client.models.get(model=MODEL_NAME)
print(f"Model: {model_info.display_name}")
print(f"Input limit: {model_info.input_token_limit:,} tokens")

# Generate dino-themed example
response = client.models.generate_content(
    model=MODEL_NAME,
    contents="Generate a short, exciting description for a dinosaur racing game level set in a prehistoric jungle at dusk.",
)

print("\nGenerated Dino Game Level Description:")
print(response.text)
