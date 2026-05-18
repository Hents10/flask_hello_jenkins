FROM python:3.11-slim

RUN useradd -m flask

WORKDIR /home/flask

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

RUN chown -R flask:flask /home/flask

USER flask

EXPOSE 5000

CMD ["python", "app.py"]