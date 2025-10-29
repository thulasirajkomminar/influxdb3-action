# influxdb3-action

This action installs and configures [InfluxDB3 core](https://docs.influxdata.com/influxdb3/core/).

# Usage

See [action.yaml](action.yaml)

## Setup and configure InfluxDB3

```yaml
steps:
  - name: Check out repo
    uses: actions/checkout@v4

  - name: Setup InfluxDB3
    uses: thulasirajkomminar/influxdb3-action@v0
    with:
      influxdb3_database: sensordata
      influxdb3_create_token: true
```
