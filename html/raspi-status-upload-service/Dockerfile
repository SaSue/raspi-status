FROM python:3.11-slim

RUN pip install flask

WORKDIR /app
COPY . /app

CMD ["python", "/app/combined-upload-server.py"]
