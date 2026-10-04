# Python 3.12: Gradio 5.23.1 breaks on 3.14
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Listen on all interfaces so the UI is reachable from outside the container
ENV GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_SERVER_PORT=7860 \
    PYTHONUNBUFFERED=1

EXPOSE 7860

CMD ["python", "app.py"]
