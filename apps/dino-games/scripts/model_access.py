#!/usr/bin/env python3

from google import genai
client = genai.Client()

print("I can access these Google Gemini models")
# This prints every model you can use with your current API key
for model in client.models.list():
    print(f"Model ID: {model.name} | Supported: {model.supported_actions}")

