FROM python:3.12-slim

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /docs

EXPOSE 8000

CMD ["zensical", "serve", "-a", "0.0.0.0:8000"]
