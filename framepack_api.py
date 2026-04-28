import os
import shutil
import logging
from pathlib import Path
from typing import Optional

import numpy as np
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse
from PIL import Image

app = FastAPI()
logger = logging.getLogger("framepack_api")


@app.post("/generate")
async def generate(
    file: UploadFile = File(...),
    output_dir: Optional[str] = Form(None),
    prompt: Optional[str] = Form(None),
    seconds: Optional[float] = Form(None),
):
    base_dir = Path(output_dir) if output_dir else Path(__file__).parent / "outputs"
    base_dir.mkdir(parents=True, exist_ok=True)
    total_seconds = seconds if seconds is not None else 5.0

    logger.info(
        "FramePack generate request received file=%s seconds=%s output_dir=%s prompt_len=%s",
        file.filename,
        total_seconds,
        str(base_dir),
        len(prompt or ""),
    )

    try:
        input_path = base_dir / f"input-{file.filename}"

        with input_path.open("wb") as input_handle:
            shutil.copyfileobj(file.file, input_handle)

        logger.info("Input file saved path=%s", str(input_path))

        image = Image.open(input_path).convert("RGB")
        input_image = np.array(image)

        from demo_gradio_f1 import process

        output_filename = None
        for update in process(
            input_image,
            prompt or "",
            "",
            31337,
            total_seconds,
            9,
            25,
            1.0,
            10.0,
            0.0,
            6,
            True,
            16,
        ):
            if update and update[0]:
                output_filename = update[0]
                logger.info("Generation progress latest_output=%s", output_filename)

        if not output_filename:
            logger.error("Generation completed without output file")
            return JSONResponse({"error": "No output generated."}, status_code=500)

        output_path = Path(output_filename)
        if output_path.parent != base_dir:
            target_path = base_dir / output_path.name
            shutil.copyfile(output_path, target_path)
            output_path = target_path

        logger.info("Generation succeeded output_path=%s", str(output_path))
        return JSONResponse({"output_path": str(output_path), "prompt": prompt or ""})
    except Exception as exc:  # pragma: no cover - runtime safety logging
        logger.exception("Generation failed with exception: %s", exc)
        return JSONResponse(
            {"error": "Generation failed", "detail": str(exc)},
            status_code=500,
        )


if __name__ == "__main__":
    import uvicorn

    host = os.getenv("FRAMEPACK_API_HOST", "127.0.0.1")
    port = int(os.getenv("FRAMEPACK_API_PORT", "8100"))
    uvicorn.run("framepack_api:app", host=host, port=port, reload=False)
