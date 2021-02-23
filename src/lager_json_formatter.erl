-module(lager_json_formatter).

%%
%% Include files
%%
-include_lib("lager/include/lager.hrl").

%%
%% Exported Functions
%%
-export([format/2, format/3]).

-spec format(lager_msg:lager_msg(),list()) -> binary().
format(Msg, Config) ->
    format(Msg, Config, []).

-spec format(lager_msg:lager_msg(), list(), list()) -> binary().
format(Message, Config, _Colors) ->
    T = [ {JsonKey, output(LagerKey, Message)} || {JsonKey, LagerKey} <- Config ],
    iolist_to_binary([jsx:encode(T), "\n"]).

-spec output(term(), lager_msg:lager_msg()) -> binary() | atom() | string().
output(message, Msg) -> 
    lager_msg:message(Msg);
output(datetime, Msg) ->
    {D, T} = lager_msg:datetime(Msg),
    iolist_to_binary([D, <<" ">>, T]);
output(date, Msg) ->
    {D, _T} = lager_msg:datetime(Msg),
    erlang:list_to_binary(D);
output(time, Msg) ->
    {_D, T} = lager_msg:datetime(Msg),
    erlang:list_to_binary(T);
output(severity, Msg) ->
    lager_msg:severity(Msg);
output(severity_upper, Msg) ->
    uppercase_severity(lager_msg:severity(Msg));
output(node, _Msg) -> 
    node();
output(metadata, Msg) ->
    MD0 = lager_msg:metadata(Msg),
    MD = [{K, make_printable(V)} || {K, V} <- MD0],
    maps:from_list(MD);
output({pterm, Key}, Msg) ->
    output({pterm, Key, ""}, Msg);
output({pterm, Key, Default}, _Msg) ->
    make_printable(maybe_get_persistent_term(Key, Default));
output(Prop, Msg) when is_atom(Prop) ->
    Metadata = lager_msg:metadata(Msg),
    make_printable(get_metadata(Prop, Metadata, <<"Undefined">>));
output({Prop, Default}, Msg) when is_atom(Prop) ->
    Metadata = lager_msg:metadata(Msg),
    make_printable(get_metadata(Prop,Metadata, output(Default, Msg)));
output({Prop, Present, Absent}, Msg) when is_atom(Prop) ->
    %% sort of like a poor man's ternary operator
    Metadata = lager_msg:metadata(Msg),
    case get_metadata(Prop, Metadata) of
        undefined ->
            [ output(V, Msg) || V <- Absent];
        _ ->
            [ output(V, Msg) || V <- Present]
    end;
output({Prop, Present, Absent, Width}, Msg) when is_atom(Prop) ->
    %% sort of like a poor man's ternary operator
    Metadata = lager_msg:metadata(Msg),
    case get_metadata(Prop, Metadata) of
        undefined ->
            [ output(V, Msg, Width) || V <- Absent];
        _ ->
            [ output(V, Msg, Width) || V <- Present]
    end;
output(Other, _) -> make_printable(Other).

output(Key, Msg, _Width) -> output(Key, Msg).

-spec make_printable(any()) -> binary() | atom() | integer().
make_printable(A) when is_atom(A) -> A;
make_printable(B) when is_binary(B) -> B; 
make_printable(I) when is_integer(I) -> I;
make_printable(P) when is_pid(P) -> list_to_binary(pid_to_list(P));
make_printable(L) when is_list(L) -> list_to_binary(L);
make_printable(Other) -> iolist_to_binary(io_lib:format("~p",[Other])).

%% persistent term was introduced in OTP 21.2, so
%% if we're running on an older OTP, just return the
%% default value.
-ifdef(OTP_RELEASE).
maybe_get_persistent_term(Key, Default) ->
    try
        persistent_term:get(Key, Default)
    catch
        _:undef -> Default
    end.
-else.
maybe_get_persistent_term(_Key, Default) -> Default.
-endif.

run_function(Function, Default) ->
    try Function() of
        Result ->
            Result
    catch
        _:_ ->
          Default
    end.

get_metadata(Key, Metadata) ->
    get_metadata(Key, Metadata, undefined).

get_metadata(Key, Metadata, Default) ->
    case lists:keyfind(Key, 1, Metadata) of
        false ->
            Default;
        {Key, Value} when is_function(Value) ->
            run_function(Value, Default);
        {Key, Value} ->
            Value
    end.

uppercase_severity(debug) -> <<"DEBUG">>;
uppercase_severity(info) -> <<"INFO">>;
uppercase_severity(notice) -> <<"NOTICE">>;
uppercase_severity(warning) -> <<"WARNING">>;
uppercase_severity(error) -> <<"ERROR">>;
uppercase_severity(critical) -> <<"CRITICAL">>;
uppercase_severity(alert) -> <<"ALERT">>;
uppercase_severity(emergency) -> <<"EMERGENCY">>;
uppercase_severity(A) when is_atom(A) ->  string:uppercase(erlang:atom_to_binary(A)).