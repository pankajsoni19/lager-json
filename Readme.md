# Lager Json formatter

This is a utility parser for lager into json. We use it to send logs to cloudwatch.

## How to use

__`rebar`__

You can use `lager-json` as a dependency in your rebar.config:

```
{deps , [
    {lager_json, ".*", {git, "https://github.com/pankajsoni19/lager-json.git", {tag, "1.0.0"}}}
]}.
```

__`erlang.mk`__

```
DEPS = lager_json
dep_lager_json = git https://github.com/pankajsoni19/lager-json 1.0.0
```

## Configure lager

In your `sys.config`

```
[
    {lager, [
        {log_root, "log" },
        {handlers, [
            {lager_file_backend, [
                {file, "debug.log"},
                {level, debug},
                {formatter, lager_json_formatter},
                {formatter_config, [
                    {message, message},
                    {level, severity},
                    {timestamp, datetime},
                    {server, node},
                    {service, my_service},
                    {metadata, metadata},
                    {process, pid}, 
                    {module, module},
                    {function, function},
                    {line, line}
                ]},
                {size, 104857600}, {date, "$D0"}, {count, 100}
            ]}
        ]}
    ]}
]
```

Essentially you can give `formatter_config` as tuple `{ json_key, lager_config}`

