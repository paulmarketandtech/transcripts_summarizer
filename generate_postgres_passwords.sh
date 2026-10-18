for v in POSTGRES_PASSWORD SUMMARIZER_OWNER_PASSWORD SUMMARIZER_APP_PASSWORD SUMMARIZER_READONLY_PASSWORD PGADMIN_PASSWORD; do
  echo "$v=$(openssl rand -hex 24)"
done >> .env
echo "PGADMIN_EMAIL=admin@example.com" >> .env
chmod 600 .env
