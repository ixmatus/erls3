-module(erls3util).
-export([
	collapse/1,
	string_join/2,
	join/1,
	filter_keyset/2,
	string_value/1,
	unix_time/1,
    region_url/1,
	url_encode/1]).
-include("erls3.hrl").
-include_lib("xmerl/include/xmerl.hrl").

region_url("us-east-1") -> "s3.amazonaws.com";
region_url(R) -> ?FORMAT("s3-~s.amazonaws.com", [R]).
    
%% Collapse equal keys into one list
consume ({K,V}, [{K,L}|T]) -> [{K,[V|L]}|T];
consume ({K,V}, L) -> [{K,[V]}|L].

collapse (L) ->
    Raw = lists:foldl( fun consume/2, [], L ),
    Ordered = lists:reverse( Raw ),
    lists:keymap( fun lists:sort/1, 2, Ordered ).

unix_time(Expires)->
    calendar:datetime_to_gregorian_seconds(calendar:universal_time()) + Expires - 62167219200.

%%collapse_empty_test() -> ?assertMatch( [], collapse( [] ) ).
%%collapse_single_test() -> ?assertMatch( [{a,[1]}], collapse( [{a,1}] ) ).
%%collapse_many_test() -> ?assertMatch( [{a,[1,2]},{b,[3]}], collapse( [ {a,1}, {a,2}, {b,3} ] ) ).
%%collapse_order_test() -> ?assertMatch( [{a,[1,2]},{b,[3]}], collapse( [ {a,1}, {a,2}, {b,3} ] ) ).

string_join(Items, Sep) ->
    lists:flatten(lists:reverse(string_join1(Items, Sep, []))).

string_join1([], _Sep, Acc) -> Acc;
string_join1([Head | []], _Sep, Acc) ->
    [Head | Acc];
string_join1([Head | Tail], Sep, Acc) ->
    string_join1(Tail, Sep, [Sep, Head | Acc]).

join ({Key,Values}) ->
    Key ++ ":" ++ string_join(Values,",").

%%join_one_test () -> ?assertMatch( "key:one", join({"key",["one"]} ) ).
%%join_two_test () -> ?assertMatch( "key:one,two", join({"key",["one","two"]} ) ).

filter_keyset (L,KeySet) -> [ {K,V} || {K,V} <- L, lists:member(K,KeySet) ].

% All the text nodes in an xml doc
string_value( #xmlDocument{ content=Content } ) -> lists:flatten(lists:map( fun string_value/1, Content ));
string_value( #xmlElement{ content=Content } ) -> lists:flatten(lists:map( fun string_value/1, Content ));
string_value( #xmlText{value=Value} ) -> Value;
string_value( [Nodes]) -> lists:flatten(lists:map( fun string_value/1, Nodes ));
string_value( _ ) ->  "".
     
%%--------------------------------------------------------------------
%% @doc url_encode - lifted from the ever precious yaws_utils.erl    
%% <pre>
%% Types:
%%  String
%% </pre>
%% @spec url_encode(String) -> String
%% @end
%%--------------------------------------------------------------------
url_encode([H|T]) ->
    if
        H >= $a, $z >= H ->
            [H|url_encode(T)];
        H >= $A, $Z >= H ->
            [H|url_encode(T)];
        H >= $0, $9 >= H ->
            [H|url_encode(T)];
        H == $_; H == $.;H == $~; H == $- -> % FIXME: more..
            [H|url_encode(T)];
        true ->
            case integer_to_hex(H) of
                [X, Y] ->
                    [$%, X, Y | url_encode(T)];
                [X] ->
                    [$%, $0, X | url_encode(T)]
            end
     end;

url_encode([]) ->
    [].
integer_to_hex(I) ->
    case catch erlang:integer_to_list(I, 16) of
        {'EXIT', _} ->
            old_integer_to_hex(I);
        Int ->
            Int
    end.

old_integer_to_hex(I) when I<10 ->
    integer_to_list(I);
old_integer_to_hex(I) when I<16 ->
    [I-10+$A];
old_integer_to_hex(I) when I>=16 ->
    N = trunc(I/16),
    old_integer_to_hex(N) ++ old_integer_to_hex(I rem 16).
