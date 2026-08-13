FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=config.settings.production

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Temporary environment required only while collecting static files
RUN printf '%s\n' \
    'SECRET_KEY=build-only-secret-key' \
    'ALLOWED_HOSTS=localhost,127.0.0.1' \
    'DJANGO_ALLOWED_HOSTS=127.0.0.1 localhost' \
    'DEBUG=False' \
    'EMAIL_HOST_USER=build@example.com' \
    'EMAIL_HOST_PASSWORD=build-only-password' \
    'GOOGLE_CLIENT_ID=build-only-google-client-id' \
    'GOOGLE_SECRET=build-only-google-secret' \
    'TWILIO_ACCOUNT_SID=build-only-sid' \
    'TWILIO_AUTH_TOKEN=build-only-token' \
    'TWILIO_PHONE_NUMBER=+10000000000' \
    'DATABASE_URL=postgresql://build:build@localhost:5432/build' \
    'SUPERUSER_USERNAME=buildadmin' \
    'SUPERUSER_EMAIL=build@example.com' \
    'SUPERUSER_PASSWORD=build-only-password' \
    > .env \
    && python manage.py collectstatic --noinput \
    && rm -f .env

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]