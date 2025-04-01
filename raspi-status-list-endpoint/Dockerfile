FROM python:3.11-slim

RUN pip install flask

COPY list-server.py /app/list-server.py

WORKDIR /app

CMD ["python", "list-server.py"]
