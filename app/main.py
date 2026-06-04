import os

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from openai import AzureOpenAI
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title="DevOps Starter Kit")

app.mount("/static", StaticFiles(directory="app/static"), name="static")

def get_openai_client() -> AzureOpenAI:
    return AzureOpenAI(
        api_key=os.getenv("AZURE_OPENAI_KEY"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
    )

class SummariseRequest(BaseModel):
    text: str

@app.get("/", include_in_schema=False)
def root():
    return FileResponse("app/static/index.html")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/summarize")
def summarize(request: SummariseRequest):
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")
    try:
        response = get_openai_client().chat.completions.create(
            model=os.getenv("AZURE_OPENAI_DEPLOYMENT"),
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a helpful assistant that "
                        "summarises text clearly and concisely in 2-3 sentences."
                    ),
                },
                {
                    "role": "user",
                    "content": f"Summarise the following text:\n\n{request.text}"
                }
            ],
            temperature=0.3,
            max_tokens=150
        )
        summary = response.choices[0].message.content
        return {"summary": summary}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))