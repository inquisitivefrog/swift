
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % cat .env 
export GEMINI_API_KEY=AIzaSyCBspj69Wkw0ub0m4SXuXZe_Gh4IH-tINw
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % cat test_pivot.py 
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

(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % ./test_pivot.py
Python + Google GenAI offers SwiftUI developers an easy way to build powerful backends and infuse their apps with intelligent, dynamic AI capabilities like content generation or smart interactions.
