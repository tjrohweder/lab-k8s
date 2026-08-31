FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DAGSTER_HOME=/opt/dagster/dagster_home \
    DAGSTER_APP=/opt/dagster/app

RUN apt-get update && apt-get install -y --no-install-recommends \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 dagster && \
    useradd -u 1000 -g dagster -d $DAGSTER_HOME -s /bin/bash dagster

WORKDIR $DAGSTER_APP

RUN mkdir -p $DAGSTER_HOME && \
    chown -R dagster:dagster /opt/dagster

COPY --chown=dagster:dagster requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY --chown=dagster:dagster repo.py .

USER dagster

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
