# Deliberately old base image (Debian 11, Python 3.9 end of life) for the lab
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 8080
# No USER line on purpose: the container runs as root, which Trivy flags
CMD ["python", "app.py"]
