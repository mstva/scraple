# Scraple
A web scrapper and deposit system data pipeline!

## Features:
- Scrape data from urls, html file and xml files
- Let users deposit their data through a deposit system
- Data pipeline for extracting, cleaning and storing data in database

## Tech Stacks
- **Backend**: Python, Django, PostgreSQL
- **Infrastructure**: Terraform, Google Cloud Compute Instance
- **Deployment**: Nginx through Linux Bash Script

---

## Backend:

### Run The Backend
```shell
chmod +x ./scripts/run_backend.sh && ./scripts/run_backend.sh
```

### Run The Tests:
- Run Pytest:
  ```shell
  .venv/bin/pytest -rP
  ```
- Run Pytest Coverage:
  ```shell
  .venv/bin/pytest --cov=backend
  ```

### Docs:
- Check Docs Coverage:
  ```shell
  .venv/bin/interrogate -v backend
  ```
- Check Docs Style:
  ```shell
  .venv/bin/pydocstyle backend
  ```
- Show Docs Locally:
  ```shell
  .venv/bin/mkdocs serve --dev-addr 127.0.0.1:9000
  ```
- Deploy Docs to GitHub Pages:
  ```shell
  .venv/bin/mkdocs gh-deploy
  ```

---

## Infrastructure:

### Setup Terraform Backend and Secrets:
- Create GCP project and get the project id
- Create a GCP storage and get the bucket name
- Download a service key file and rename it to `infrastructure/.gcp_creds.json`
- Copy `infrastructure/.backend.hcl.sample` and rename it to `infrastructure/.backend.hcl`
- Copy `infrastructure/.secrets.auto.tfvars.sample` and rename it to `infrastructure/.secrets.auto.tfvars`

### Setup SSH:
- Generate an SSH Key.
- Create the folder `infrastructure/.ssh` and copy `id_rsa.pub` and `id_rsa` inside it

### Run Terraform Commands:
- Create an alias for terraform command
  ```shell
  alias TF=docker compose -f infrastructure/.docker-compose.yml run --rm terraform
  ```
- terraform init
  ```shell
  TF init -backend-config=.backend.hcl
  ```
- terraform apply gcp
  ```shell
  TF apply -target="module.gcp" --auto-approve
  ```
- terraform destroy gcp
  ```shell
  TF destroy -target="module.gcp" --auto-approve
  ```
- terraform output gcp
  ```shell
  TF output gcp
  ```
