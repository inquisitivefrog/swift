#!/usr/bin/env python3

import os
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Explain in one sentence why SwiftUI developers might enjoy Python + Google GenAI."
)

print(response.text)
