(*return true if a is a subset of b*)
let subset a b =
    List.for_all (fun x -> List.mem x b) a;;

(*return true is a and b are equal sets *)
let equal_sets a b =
  	subset a b && subset b a;;

(*union two sets *)
let rec set_union a b = match a with
    []->b
    |head::rest-> if List.mem head b then set_union rest b
    else set_union rest b@[head] ;;

(* find intersection of two sets*)
let set_intersection a b =
    List.filter (fun x -> List.mem x b) a ;;

(* find diff of two sets*)
let set_diff a b =
    List.filter (fun x -> not(List.mem x b)) a;;

(* compute fixed point*)
let rec computed_fixed_point eq f x =
    if eq x (f x) then x
    else computed_fixed_point eq f (f x);;

(* return reachable rules*)

type ('nonterminal, 'terminal) symbol =
    | N of 'nonterminal
    | T of 'terminal;;

let rec determine_nt list = match list with
    [] -> []
    | T _ :: rest -> determine_nt rest
    | N head :: rest -> [head]@(determine_nt rest);;

let rec filter non_term rules_list = non_term :: (match rules_list with
    []->[]
    |head :: rest -> match head with
         |(a,b) -> if a = non_term then
          (determine_nt b)@(filter non_term rest)
          else (filter non_term rest));;

let rec filter_list nt_list rules_list = nt_list @ (match nt_list with
    [] -> []
    | head::rest -> (filter head rules_list) @ (filter_list rest rules_list));;

let find_reachable g =
    (fun x -> (filter_list x (Stdlib.snd g)));;

let convert_to_list newer org =
    List.filter(fun (x,y) -> List.mem x newer)org;;

let reachable_rules g = convert_to_list (computed_fixed_point
    equal_sets (find_reachable g) [Stdlib.fst g])
    (Stdlib.snd g);;

let filter_reachable g = (Stdlib.fst g),(reachable_rules g);;
