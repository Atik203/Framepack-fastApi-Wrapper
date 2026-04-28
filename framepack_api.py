import os
import shutil
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse

app = FastAPI()


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    output_dir: Optional[str] = Form(None),
    prompt: Optional[str] = Form(None),
):
    # Placeholder for demo: save input as output until FramePack inference is wired in.
    base_dir = Path(output_dir) if output_dir else Path(__file__).parent / "outputs"
    base_dir.mkdir(parents=True, exist_ok=True)

    input_path = base_dir / f"input-{file.filename}"
    output_path = base_dir / f"output-{file.filename}"

    with input_path.open("wb") as input_handle:
        shutil.copyfileobj(file.file, input_handle)

    shutil.copyfile(input_path, output_path)

    return JSONResponse({"output_path": str(output_path), "prompt": prompt or ""})


if __name__ == "__main__":
    import uvicorn

    host = os.getenv("FRAMEPACK_API_HOST", "127.0.0.1")
    port = int(os.getenv("FRAMEPACK_API_PORT", "8100"))
    uvicorn.run("framepack_api:app", host=host, port=port, reload=False)
