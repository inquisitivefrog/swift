
(⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % source /Users/tim/Documents/workspace/swift/apps/dino-games/scripts/dino-games/bin/activate
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % ./self_test.py 
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % python3 -m pip install --upgrade pip
Requirement already satisfied: pip in ./dino-games/lib/python3.14/site-packages (25.3)
Collecting pip
  Downloading pip-26.0-py3-none-any.whl.metadata (4.7 kB)
Downloading pip-26.0-py3-none-any.whl (1.8 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.8/1.8 MB 5.6 MB/s  0:00:00
Installing collected packages: pip
  Attempting uninstall: pip
    Found existing installation: pip 25.3
    Uninstalling pip-25.3:
      Successfully uninstalled pip-25.3
Successfully installed pip-26.0

(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % python3 -m pip install --upgrade Pillow
Collecting Pillow
  Downloading pillow-12.1.0-cp314-cp314-macosx_11_0_arm64.whl.metadata (8.8 kB)
Downloading pillow-12.1.0-cp314-cp314-macosx_11_0_arm64.whl (4.7 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 4.7/4.7 MB 5.7 MB/s  0:00:00
Installing collected packages: Pillow

(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip install -q -U google-generativeai
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip install -U google-generativeai
Requirement already satisfied: google-generativeai in ./dino-games/lib/python3.14/site-packages (0.8.6)
Requirement already satisfied: google-ai-generativelanguage==0.6.15 in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (0.6.15)
Requirement already satisfied: google-api-core in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (2.25.2)
Requirement already satisfied: google-api-python-client in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (2.188.0)
Requirement already satisfied: google-auth>=2.15.0 in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (2.49.0.dev0)
Requirement already satisfied: protobuf in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (5.29.5)
Requirement already satisfied: pydantic in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (2.12.5)
Requirement already satisfied: tqdm in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (4.67.2)
Requirement already satisfied: typing-extensions in ./dino-games/lib/python3.14/site-packages (from google-generativeai) (4.15.0)
Requirement already satisfied: proto-plus<2.0.0dev,>=1.22.3 in ./dino-games/lib/python3.14/site-packages (from google-ai-generativelanguage==0.6.15->google-generativeai) (1.27.1)
Requirement already satisfied: googleapis-common-protos<2.0.0,>=1.56.2 in ./dino-games/lib/python3.14/site-packages (from google-api-core->google-generativeai) (1.72.0)
Requirement already satisfied: requests<3.0.0,>=2.18.0 in ./dino-games/lib/python3.14/site-packages (from google-api-core->google-generativeai) (2.32.5)
Requirement already satisfied: grpcio<2.0.0,>=1.33.2 in ./dino-games/lib/python3.14/site-packages (from google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.10.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,!=2.8.*,!=2.9.*,<3.0.0dev,>=1.34.1->google-ai-generativelanguage==0.6.15->google-generativeai) (1.76.0)
Requirement already satisfied: grpcio-status<2.0.0,>=1.33.2 in ./dino-games/lib/python3.14/site-packages (from google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.10.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,!=2.8.*,!=2.9.*,<3.0.0dev,>=1.34.1->google-ai-generativelanguage==0.6.15->google-generativeai) (1.71.2)
Requirement already satisfied: pyasn1-modules>=0.2.1 in ./dino-games/lib/python3.14/site-packages (from google-auth>=2.15.0->google-generativeai) (0.4.2)
Requirement already satisfied: cryptography>=38.0.3 in ./dino-games/lib/python3.14/site-packages (from google-auth>=2.15.0->google-generativeai) (46.0.4)
Requirement already satisfied: charset_normalizer<4,>=2 in ./dino-games/lib/python3.14/site-packages (from requests<3.0.0,>=2.18.0->google-api-core->google-generativeai) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in ./dino-games/lib/python3.14/site-packages (from requests<3.0.0,>=2.18.0->google-api-core->google-generativeai) (3.11)
Requirement already satisfied: urllib3<3,>=1.21.1 in ./dino-games/lib/python3.14/site-packages (from requests<3.0.0,>=2.18.0->google-api-core->google-generativeai) (2.6.3)
Requirement already satisfied: certifi>=2017.4.17 in ./dino-games/lib/python3.14/site-packages (from requests<3.0.0,>=2.18.0->google-api-core->google-generativeai) (2026.1.4)
Requirement already satisfied: cffi>=2.0.0 in ./dino-games/lib/python3.14/site-packages (from cryptography>=38.0.3->google-auth>=2.15.0->google-generativeai) (2.0.0)
Requirement already satisfied: pycparser in ./dino-games/lib/python3.14/site-packages (from cffi>=2.0.0->cryptography>=38.0.3->google-auth>=2.15.0->google-generativeai) (3.0)
Requirement already satisfied: pyasn1<0.7.0,>=0.6.1 in ./dino-games/lib/python3.14/site-packages (from pyasn1-modules>=0.2.1->google-auth>=2.15.0->google-generativeai) (0.6.2)
Requirement already satisfied: httplib2<1.0.0,>=0.19.0 in ./dino-games/lib/python3.14/site-packages (from google-api-python-client->google-generativeai) (0.31.2)
Requirement already satisfied: google-auth-httplib2<1.0.0,>=0.2.0 in ./dino-games/lib/python3.14/site-packages (from google-api-python-client->google-generativeai) (0.3.0)
Requirement already satisfied: uritemplate<5,>=3.0.1 in ./dino-games/lib/python3.14/site-packages (from google-api-python-client->google-generativeai) (4.2.0)
Requirement already satisfied: pyparsing<4,>=3.1 in ./dino-games/lib/python3.14/site-packages (from httplib2<1.0.0,>=0.19.0->google-api-python-client->google-generativeai) (3.3.2)
Requirement already satisfied: annotated-types>=0.6.0 in ./dino-games/lib/python3.14/site-packages (from pydantic->google-generativeai) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in ./dino-games/lib/python3.14/site-packages (from pydantic->google-generativeai) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in ./dino-games/lib/python3.14/site-packages (from pydantic->google-generativeai) (0.4.2)
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % 

(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip install -q -U google-genai
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip install -U google-genai 
Requirement already satisfied: google-genai in ./dino-games/lib/python3.14/site-packages (1.61.0)
Requirement already satisfied: anyio<5.0.0,>=4.8.0 in ./dino-games/lib/python3.14/site-packages (from google-genai) (4.12.1)
Requirement already satisfied: google-auth<3.0.0,>=2.47.0 in ./dino-games/lib/python3.14/site-packages (from google-auth[requests]<3.0.0,>=2.47.0->google-genai) (2.49.0.dev0)
Requirement already satisfied: httpx<1.0.0,>=0.28.1 in ./dino-games/lib/python3.14/site-packages (from google-genai) (0.28.1)
Requirement already satisfied: pydantic<3.0.0,>=2.9.0 in ./dino-games/lib/python3.14/site-packages (from google-genai) (2.12.5)
Requirement already satisfied: requests<3.0.0,>=2.28.1 in ./dino-games/lib/python3.14/site-packages (from google-genai) (2.32.5)
Requirement already satisfied: tenacity<9.2.0,>=8.2.3 in ./dino-games/lib/python3.14/site-packages (from google-genai) (9.1.2)
Requirement already satisfied: websockets<15.1.0,>=13.0.0 in ./dino-games/lib/python3.14/site-packages (from google-genai) (15.0.1)
Requirement already satisfied: typing-extensions<5.0.0,>=4.11.0 in ./dino-games/lib/python3.14/site-packages (from google-genai) (4.15.0)
Requirement already satisfied: distro<2,>=1.7.0 in ./dino-games/lib/python3.14/site-packages (from google-genai) (1.9.0)
Requirement already satisfied: sniffio in ./dino-games/lib/python3.14/site-packages (from google-genai) (1.3.1)
Requirement already satisfied: idna>=2.8 in ./dino-games/lib/python3.14/site-packages (from anyio<5.0.0,>=4.8.0->google-genai) (3.11)
Requirement already satisfied: pyasn1-modules>=0.2.1 in ./dino-games/lib/python3.14/site-packages (from google-auth<3.0.0,>=2.47.0->google-auth[requests]<3.0.0,>=2.47.0->google-genai) (0.4.2)
Requirement already satisfied: cryptography>=38.0.3 in ./dino-games/lib/python3.14/site-packages (from google-auth<3.0.0,>=2.47.0->google-auth[requests]<3.0.0,>=2.47.0->google-genai) (46.0.4)
Requirement already satisfied: certifi in ./dino-games/lib/python3.14/site-packages (from httpx<1.0.0,>=0.28.1->google-genai) (2026.1.4)
Requirement already satisfied: httpcore==1.* in ./dino-games/lib/python3.14/site-packages (from httpx<1.0.0,>=0.28.1->google-genai) (1.0.9)
Requirement already satisfied: h11>=0.16 in ./dino-games/lib/python3.14/site-packages (from httpcore==1.*->httpx<1.0.0,>=0.28.1->google-genai) (0.16.0)
Requirement already satisfied: annotated-types>=0.6.0 in ./dino-games/lib/python3.14/site-packages (from pydantic<3.0.0,>=2.9.0->google-genai) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in ./dino-games/lib/python3.14/site-packages (from pydantic<3.0.0,>=2.9.0->google-genai) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in ./dino-games/lib/python3.14/site-packages (from pydantic<3.0.0,>=2.9.0->google-genai) (0.4.2)
Requirement already satisfied: charset_normalizer<4,>=2 in ./dino-games/lib/python3.14/site-packages (from requests<3.0.0,>=2.28.1->google-genai) (3.4.4)
Requirement already satisfied: urllib3<3,>=1.21.1 in ./dino-games/lib/python3.14/site-packages (from requests<3.0.0,>=2.28.1->google-genai) (2.6.3)
Requirement already satisfied: cffi>=2.0.0 in ./dino-games/lib/python3.14/site-packages (from cryptography>=38.0.3->google-auth<3.0.0,>=2.47.0->google-auth[requests]<3.0.0,>=2.47.0->google-genai) (2.0.0)
Requirement already satisfied: pycparser in ./dino-games/lib/python3.14/site-packages (from cffi>=2.0.0->cryptography>=38.0.3->google-auth<3.0.0,>=2.47.0->google-auth[requests]<3.0.0,>=2.47.0->google-genai) (3.0)
Requirement already satisfied: pyasn1<0.7.0,>=0.6.1 in ./dino-games/lib/python3.14/site-packages (from pyasn1-modules>=0.2.1->google-auth<3.0.0,>=2.47.0->google-auth[requests]<3.0.0,>=2.47.0->google-genai) (0.6.2)
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % 

(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip install python-dotenv
Collecting python-dotenv
  Downloading python_dotenv-1.2.1-py3-none-any.whl.metadata (25 kB)
Downloading python_dotenv-1.2.1-py3-none-any.whl (21 kB)
Installing collected packages: python-dotenv
Successfully installed python-dotenv-1.2.1

(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip freeze > requirements.txt
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % cat requirements.txt 
annotated-types==0.7.0
anyio==4.12.1
certifi==2026.1.4
cffi==2.0.0
charset-normalizer==3.4.4
cryptography==46.0.4
distro==1.9.0
google-ai-generativelanguage==0.6.15
google-api-core==2.25.2
google-api-python-client==2.188.0
google-auth==2.49.0.dev0
google-auth-httplib2==0.3.0
google-genai==1.61.0
google-generativeai==0.8.6
googleapis-common-protos==1.72.0
grpcio==1.76.0
grpcio-status==1.71.2
h11==0.16.0
httpcore==1.0.9
httplib2==0.31.2
httpx==0.28.1
idna==3.11
pillow==12.1.0
proto-plus==1.27.1
protobuf==5.29.5
pyasn1==0.6.2
pyasn1_modules==0.4.2
pycparser==3.0
pydantic==2.12.5
pydantic_core==2.41.5
pyparsing==3.3.2
python-dotenv==1.2.1
requests==2.32.5
sniffio==1.3.1
tenacity==9.1.2
tqdm==4.67.2
typing-inspection==0.4.2
typing_extensions==4.15.0
uritemplate==4.2.0
urllib3==2.6.3
websockets==15.0.1
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip install -r requirements.txt
(dino-games) (⎈|N/A:N/A)tim@Timothys-MacBook-Air scripts % pip show google-genai
Name: google-genai
Version: 1.61.0
Summary: GenAI Python SDK
Home-page: https://github.com/googleapis/python-genai
Author: 
Author-email: Google LLC <googleapis-packages@google.com>
License-Expression: Apache-2.0
Location: /Users/tim/Documents/workspace/swift/apps/dino-games/scripts/dino-games/lib/python3.14/site-packages
Requires: anyio, distro, google-auth, httpx, pydantic, requests, sniffio, tenacity, typing-extensions, websockets
Required-by: 

