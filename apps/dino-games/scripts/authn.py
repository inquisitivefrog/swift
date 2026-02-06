#!/usr/bin/env python3

import os
from google import genai
from google.genai.types import HarmCategory, HarmBlockThreshold

# 1. AUTHENTICATION
# This pulls the key you saved in your .env
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client()

