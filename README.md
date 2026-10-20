install docker https://docs.docker.com/compose/install/

This highlights the microservice tech stack for

POC E-Commerce Sales Dashboard — AI powered by Claude (Anthropic) — Backend: FastAPI + MariaDB — Frontend: Vite + React TSX

THE Sales Dashboard with AI Insights
http://<localhost>/

and 

PHP 8.4, in this proof of concept it shares one DB, make sure to save .env on your
local copy once you cloned this

The CRUD HR Proof OF Concept
http://<localhost>/hrecs

.env
# MariaDB — all inside container, connects via localhost
DB_USER=mypoc_user
DB_PASSWORD=mypoc_pass
DB_HOST=mariadb118
DB_PORT=3306
DB_NAME=mypoc_proofofconceptv1

GCP_JSON_PATH=/home/yourpath/YOURexisting.json
GOOGLE_APPLICATION_CREDENTIALS=/app/YOURgcp_service_account.json
GCP_PROJECT=subaiproj
GCP_REGION=global
#without this AI Insight won't work get it from Google AI Studio
GEMINI_API_KEY=YOURGEMINIKEY
#just default to gemini since it's free not paid like claude
CLAUDE_MODEL=gemini-3.5-flash-lite
DEEPSEEK_API_KEY=sk-YOURDEEPSEEKEY
GEMINI_FALLBACK_MODELS=gemini-3.5-flash-lite
MIXROUTE_API_KEY=sk-YOURMIXROUTEKEY
AI_HTTP_TIMEOUT=15
MAX_QUESTION_CHARS=1000
