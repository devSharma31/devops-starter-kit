from fastapi import FastAPI
from fastapi.responses import RedirectResponse

app = FastAPI(title="DevOps Starter Kit")

@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/health", status_code=307)

@app.get("/health")
def health():
    return {"status": "ok"}
