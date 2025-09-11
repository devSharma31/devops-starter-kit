
from fastapi import FastAPI

app = FastAPI(title="DevOps Starter Kit")

@app.get("/health")
def health():
    return {"status": "ok"}
