PROJECT = lager_json
PROJECT_VERSION = $(shell head -n 1 relx.config | awk '{split($$0, a, "\""); print a[2]}')

app:: rebar.config

DEPS = lager jsx
dep_lager = git https://github.com/erlang-lager/lager 3.8.1
dep_jsx = git https://github.com/talentdeficit/jsx.git v3.0.0

include erlang.mk

ERLC_OPTS := $(filter-out -Werror,$(ERLC_OPTS))

ERLC_COMPILE_OPTS= +'{parse_transform, lager_transform}'
ERLC_OPTS += $(ERLC_COMPILE_OPTS)
TEST_ERLC_OPTS += $(ERLC_COMPILE_OPTS)
