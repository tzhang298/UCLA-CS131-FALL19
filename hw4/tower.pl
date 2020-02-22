
% define constrain (row/col size, domain, element uniqueness)
constrain(_, []).
constrain(N, [H|T]) :-
  length(H, N),
  fd_domain(H, 1, N),
  fd_all_different(H),
  constrain(N, T).

% define transpose
transpose([], []).
transpose([F|Ft], Tt) :-
    transpose(F, [F|Ft], Tt).

transpose([], _, []).
transpose([_|Rt], Mt, [Tt|Ttt]) :-
        taillist(Mt, Tt, Mt1),
        transpose(Rt, Mt1, Ttt).

taillist([], [], []).
taillist([[F|Ot]|Rest], [F|Ft], [Ot|Ott]) :-
        taillist(Rest, Ft, Ott).

% define countRow in countTower
countRow([], Count, X, _) :-
  X = Count.
countRow([H|T], Count, X, Prev) :-
  (Prev < H ->
    Y is X + 1,
    countRow(T, Count, Y, H);
    countRow(T, Count, X, Prev)
  ).

% define countTower in viewCounts
countTower([], []).
countTower([Row|RT], [Count|CT]) :-
  countRow(Row, Count, 0, 0),
  countTower(RT, CT).

% define viewCounts in tower, plain_tower
viewCounts(T, T_tr, Top, Bottom, Left, Right) :-
  countTower(T, Left),
  maplist(reverse, T, T_reverse),
  countTower(T_reverse, Right),
  countTower(T_tr, Top),
  maplist(reverse, T_tr, T_tr_reverse),
  countTower(T_tr_reverse, Bottom).

% define tower utilize: constrain;transpose;maplist;viewCounts
tower(N, T, C) :-
  length(T, N),
  constrain(N, T),
  transpose(T, T_trans),
  constrain(N, T_trans),
  C = counts(Top, Bottom, Left, Right),
  length(Top, N),
  length(Bottom, N),
  length(Left, N),
  length(Right, N),

  maplist(fd_labeling, T),
  viewCounts(T, T_trans, Top, Bottom, Left, Right).

%  define Ambiguous Towers
ambiguous(N, C, T1, T2) :-
  tower(N, T1, C),
  tower(N, T2, C),
  T1 \= T2.

% define uniAll in uniRow
uniAll([]).
uniAll([H|T]) :- member(H, T), !, fail.
uniAll([_|T]) :- uniAll(T).

% define uniRow in plain_tower
uniRow(N, Row) :-
  length(Row, N),
  maplist(between(1, N), Row),
  uniAll(Row).

%  define plain_tower(using length, transpose, maplist,viewCounts)
plain_tower(N, T, C) :-

  length(T, N),
  maplist(uniRow(N), T),
  transpose(T, T_tr),
  maplist(uniRow(N), T_tr),
  C = counts(Top, Bottom, Left, Right),
  length(Top, N),
  length(Bottom, N),
  length(Left, N),
  length(Right, N),
  viewCounts(T, T_tr, Top, Bottom, Left, Right).

%  measure
towerTest(T) :-
  statistics(cpu_time, [Start|_]),
  tower(4, _ ,counts([3,3,2,1],[2,1,2,4],[4,2,1,2],[1,2,3,3])),
  statistics(cpu_time, [End|_]),
  T is End - Start + 1.

plainTest(T) :-
  statistics(cpu_time, [Start|_]),
  plain_tower(4, _ ,counts([3,3,2,1],[2,1,2,4],[4,2,1,2],[1,2,3,3])),
  statistics(cpu_time, [End|_]),
  T is End - Start.

speedup(Ratio) :-
  towerTest(T),
  plainTest(XT),
  Ratio is XT / T.
