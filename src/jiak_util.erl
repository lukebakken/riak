-module(jiak_util).
-export([jiak_required_props/0,
         jiak_module_for_bucket/1, 
         get_jiak_module/1, 
         jiak_module_for_bucket/1,
         bucket_from_uri/1]).

%% @private
jiak_required_props() -> [allowed_fields,required_fields,read_mask,write_mask].

%% @private
default_jiak_module(BucketName) when is_atom(BucketName) ->
    BucketProps = riak_bucket:get_bucket(BucketName),
    case lists:filter(
           fun(I) -> 
                   proplists:get_value(I, BucketProps) =:= undefined
           end, 
           ?JIAK_REQUIRED_PROPS) of
        [] ->
            jiak_default:new(BucketProps);
        _ ->
            undefined
    end.

%% @private
get_jiak_module(ReqData) ->
    case bucket_from_uri(ReqData) of
        {ok, Bucket} when is_atom(Bucket) ->
            jiak_module_for_bucket(Bucket);
        {error, no_such_bucket} -> 
            undefined
    end.

%% @private
jiak_module_for_bucket(Bucket) when is_atom(Bucket) ->
    case code:which(Bucket) of
        non_existing ->
            case default_jiak_module(Bucket) of
                undefined -> undefined;
                Mod when is_tuple(Mod) -> Mod
            end;
        ModPath when is_list(ModPath) -> Bucket
    end.

%% @spec bucket_from_uri(webmachine:wrq()) ->
%%         {ok, atom()}|{error, no_such_bucket}
%% @doc Extract the bucket name, as an atom, from the request URI.
%%      The bucket name must be an existing atom, or this function
%%      will return {error, no_such_bucket}
bucket_from_uri(RD) ->
    try {ok, list_to_existing_atom(wrq:path_info(bucket, RD))}
    catch _:_ -> {error, no_such_bucket} end.
