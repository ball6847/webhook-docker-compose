Webhook Docker Compose
======================

docker-compose file example

```yml
version: "3.7"

services:
  webhook:
    image: ball6847/webhook-docker-compose:0.1.0
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 9000:9000
    environment:
      GIT_CLONE_URL: git@github.com:ball6847/webhook-docker-compose.git
      GIT_PROJECT_PATH: example
      GIT_AUTHOR_NAME: John Doe
      GIT_AUTHOR_EMAIL: john@doe
      GIT_COMMITTER_NAME: John Doe
      GIT_COMMITTER_EMAIL: john@doe
      COMPOSE_PROJECT_NAME: webhook
      GIT_PRIVATE_KEY_FILE: /run/secrets/git_private_key
      WEBHOOK_MATCH_TOKEN_FILE: /run/secrets/webhook_token_file
    secrets:
      - git_private_key
      - webhook_token_file

secrets:
  git_private_key:
    file: "${GIT_PRIVATE_KEY_FILE}"
  webhook_token_file:
    file: webhook_token.txt
```


